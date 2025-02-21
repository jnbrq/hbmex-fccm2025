
def bundle(n: int):
    assert (isinstance(n, int) and n > 0)

    def create_class(n: int):
        assert (isinstance(n, int) and n > 0)

        def scala_class(i: int):
            str1 = ",\n".join(map(lambda i: f"T{i + 1} <: Data", range(i)))
            str2 = ",\n".join(map(lambda i: f"gen{i + 1}: T{i + 1}", range(i)))
            str3 = "\n".join(
                map(lambda i: f"val _{i + 1} = gen{i + 1}.cloneType", range(i)))
            print(
                f"class Bundle{i}[{str1}]\n({str2}) extends Bundle {{{str3}\n}}")

        for i in range(n):
            scala_class(1 + i)

    def create_bundlen(n: int):
        assert (isinstance(n, int) and n > 0)

        def apply(i: int):
            str1 = ",\n".join(map(lambda i: f"T{i + 1} <: Data", range(i)))
            str2 = ",\n".join(
                map(lambda i: f"gen{i + 1} : T{i + 1}", range(i)))
            str3 = ",\n".join(map(lambda i: f"T{i + 1}", range(i)))
            str4 = ",\n".join(map(lambda i: f"gen{i + 1}", range(i)))
            print(f"def apply[{str1}]({str2}): Bundle{i}[{str3}] = ")
            print(f"new Bundle{i}({str4})")

        print("object BundleN {")
        for i in range(n):
            apply(1 + i)
        print("}")

    def create_wirebundlen(n: int):
        assert (isinstance(n, int) and n > 0)

        def apply(i: int):
            str1 = ",\n".join(map(lambda i: f"T{i + 1} <: Data", range(i)))
            str2 = ",\n".join(map(lambda i: f"t{i + 1} : T{i + 1}", range(i)))
            str3 = ",\n".join(map(lambda i: f"T{i + 1}", range(i)))
            str4 = ",\n".join(
                map(lambda i: f"chiselTypeOf(t{i + 1})", range(i)))
            str5 = "\n".join(
                map(lambda i: f"result._{i + 1} <> t{i + 1}", range(i)))
            print(f"def apply[{str1}]({str2}): Bundle{i}[{str3}] = {{")
            print(f"val result = Wire(new Bundle{i}({str4}))")
            print(str5)
            print(f"result }}")

        print("object WireBundleN {")
        for i in range(n):
            apply(1 + i)
        print("}")

    create_class(n)
    create_bundlen(n)
    create_wirebundlen(n)


def zipper(n: int):
    assert (isinstance(n, int) and n > 0)

    def apply(i: int, irrevocable: bool):
        str1 = ",\n".join(map(lambda i: f"T{i + 1} <: Data", range(i)))
        str2 = ",\n".join(
            map(lambda i: f"rv{i + 1}: ReadyValidIO[T{i + 1}]", range(i)))
        str3 = ",".join(map(lambda i: f"rv{i + 1}.bits", range(i)))
        str4 = ",".join(map(lambda i: f"rv{i + 1}", range(i)))

        x1 = "apply" if not irrevocable else "irrevocable"
        x2 = "decoupled" if not irrevocable else "irrevocable"

        print(f"def {x1}[{str1}]({str2}) = {{")
        print(f"val rv = Wrap.{x2}(WireBundleN({str3}))")
        print(f"JoinUtils.join(Seq({str4}), rv)")
        print(f"rv")
        print(f"}}")

    for i in range(n):
        apply(1 + i, False)
        apply(1 + i, True)


if __name__ == "__main__":
    bundle(8)
    zipper(8)
