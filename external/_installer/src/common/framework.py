from typing import *

import os
import shutil
import subprocess

import abc
import getpass

StrOrBytesPath: TypeAlias = str | bytes | os.PathLike[str] | os.PathLike[bytes]


def shexpand(s: str) -> str:
    result = subprocess.run(["sh", "-c", f"echo \"{s}\""], capture_output=True, text=True)
    return result.stdout.strip()


class TaskException(Exception):
    pass


class Context:
    def __init__(self, prefix: str, log_fname: str = "task_log"):
        self._tasks: List["Task"] = []

        self._prefix: str = prefix
        self._log_fname: str = f"{os.getcwd()}{os.sep}{log_fname}"

        self._indent_n = 0
        self._indent = "> "

        self._sudo_passwd = None

        os.makedirs(self._prefix, exist_ok=True)
        os.environ["PATH"] = f"{self._prefix}{os.pathsep}{os.environ["PATH"]}"

    def needs_command(self, command: str) -> None:
        if shutil.which(command) is None:
            raise TaskException(f"command not found: {command}")

    def has_command(self, command: str) -> None:
        import shutil
        return shutil.which(command) is not None

    def _append_task(self, task: "Task") -> None:
        self._tasks.append(task)

    def run(self) -> None:
        self.log(f"installing to prefix '{self.prefix()}'")

        for task in self._tasks:
            task.run()

    def prefix(self, path: Optional[str] = None) -> str:
        if path is None:
            return self._prefix
        else:
            return f"{self._prefix}{os.sep}{path}"

    def log(self, s: str) -> None:
        print(f"{self._indent}{s}")

    def indent_in(self) -> None:
        self._indent_n += 1
        self._indent = ("  " * self._indent_n) + "> "

    def indent_out(self) -> None:
        if self._indent_n > 0:
            self._indent_n -= 1

        self._indent = ("  " * self._indent_n) + "> "

    def run_command(self, cmd: List[str], cwd: StrOrBytesPath = ".", fail_ok: bool = False) -> bool:
        self.log(f"running command: '{' '.join(cmd)}' in '{cwd}'")

        with open(f"{self._log_fname}.out", "a") as out, open(f"{self._log_fname}.err", "a") as err:
            out.write(f"=== '{' '.join(cmd)}' in '{cwd}' ===\n")
            out.flush()

            err.write(f"=== '{' '.join(cmd)}' in '{cwd}' ===\n")
            err.flush()

            result = subprocess.run(
                cmd,
                cwd=cwd,
                stdout=out,
                stderr=err
            )

            if result.returncode != 0:
                if fail_ok:
                    return False

                raise TaskException(
                    f"Command failed: {' '.join(cmd)}, please check '{self._log_fname}.out' and '{self._log_fname}.err' files!"
                )

            return True

    def run_command_sudo(self, cmd: List[str], cwd: StrOrBytesPath = ".", fail_ok: bool = False) -> None:
        if not self.has_command("sudo"):
            return self.run_command(cmd=cmd, cwd=cwd, fail_ok=fail_ok)

        else:
            full_cmd = ["sudo", "-S", "-E"] + cmd
            self.log(f"running command: '{' '.join(full_cmd)}' in '{cwd}'")

            if self._sudo_passwd is None:
                self._sudo_passwd = getpass.getpass(self._indent + "Please type your sudo password: ")

            with open(f"{self._log_fname}.out", "a") as out, open(f"{self._log_fname}.err", "a") as err:
                out.write(f"=== '{' '.join(full_cmd)}' in '{cwd}' ===\n")
                out.flush()

                err.write(f"=== '{' '.join(full_cmd)}' in '{cwd}' ===\n")
                err.flush()

                result = subprocess.run(
                    full_cmd,
                    cwd=cwd,
                    input=self._sudo_passwd.encode(),
                    stdout=out,
                    stderr=err
                )

                if result.returncode != 0:
                    if fail_ok:
                        return False

                    raise TaskException(
                        f"Command failed: {' '.join(full_cmd)}, please check '{self._log_fname}.out' and '{self._log_fname}.err' files!"
                    )

            return True

    def run_sh(self, cmd: str, cwd: StrOrBytesPath = ".", fail_ok: bool = False):
        return self.run_command(["sh", "-c", cmd], cwd=cwd, fail_ok=fail_ok)

    def run_sh_sudo(self, cmd: str, cwd: StrOrBytesPath = ".", fail_ok: bool = False):
        return self.run_command_sudo(["sh", "-c", cmd], cwd=cwd, fail_ok=fail_ok)

    def remove_logs(self) -> None:
        os.remove(f"{self._log_fname}.out")
        os.remove(f"{self._log_fname}.err")


class Task(abc.ABC):
    def __init__(self, context: Context, name: str = "task"):
        context._append_task(self)
        self._context = context
        self._name = name
        self._attrs: Dict[str, str] = {}

    @property
    def name(self) -> str:
        return self._name

    @abc.abstractmethod
    def main(self) -> None:
        ...

    @property
    def context(self) -> Context:
        return self._context

    @property
    def ctx(self) -> Context:
        return self._context

    def run(self) -> None:
        self.ctx.log(f"running task: {self.name}")
        self.ctx.indent_in()

        self.main()

        self.ctx.indent_out()
