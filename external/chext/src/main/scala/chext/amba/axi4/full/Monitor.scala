package chext.amba.axi4.full

import chisel3._
import chisel3.util._
import chisel3.experimental.prefix

import chext.amba.axi4

object Monitor {
  def apply(interface: axi4.full.Interface, name: String = "Monitor"): Unit = prefix(name) {
    val ctr = RegInit(0.U(32.W))
    ctr := ctr + 1.U

    when(interface.ar.fire) {
      printf(
        s"[axi4.full.Monitor: ${name}] ctr = %d, AR = { id = %d, addr = 0x%x, burst = 0x%x, len = %d }",
        ctr,
        interface.ar.bits.id,
        interface.ar.bits.addr,
        interface.ar.bits.burst,
        interface.ar.bits.len
      )
    }

    when(interface.r.fire) {
      printf(
        s"[axi4.full.Monitor: ${name}] ctr = %d, R = { id = %d, resp = 0x%x, last = %d, data = 0x%x }",
        ctr,
        interface.r.bits.id,
        interface.r.bits.resp,
        interface.r.bits.last,
        interface.r.bits.data
      )
    }

    when(interface.aw.fire) {
      printf(
        s"[axi4.full.Monitor: ${name}] ctr = %d, AW = { id = %d, addr = 0x%x, burst = 0x%x, len = %d }",
        ctr,
        interface.aw.bits.id,
        interface.aw.bits.addr,
        interface.aw.bits.burst,
        interface.aw.bits.len
      )
    }

    when(interface.w.fire) {
      printf(
        s"[axi4.full.Monitor: ${name}] ctr = %d, R = { last = %d, strb = 0x%x, data = 0x%x }",
        ctr,
        interface.w.bits.last,
        interface.w.bits.strb,
        interface.w.bits.data
      )
    }

    when(interface.b.fire) {
      printf(
        s"[axi4.full.Monitor: ${name}] ctr = %d, R = { id = %d, resp = 0x%x }",
        ctr,
        interface.b.bits.id,
        interface.b.bits.resp
      )
    }
  }
}
