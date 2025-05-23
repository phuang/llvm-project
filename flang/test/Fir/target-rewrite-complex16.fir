// RUN: fir-opt --target-rewrite="target=x86_64-unknown-linux-gnu" %s | FileCheck %s
// RUN: fir-opt --target-rewrite="target=loongarch64-unknown-linux-gnu" %s | FileCheck %s

// Test that we rewrite the signature and body of a func.function that returns a
// complex<16>.
func.func @returncomplex16() -> complex<f128> {
  %1 = fir.undefined complex<f128>
  %2 = arith.constant 2.0 : f128
  %3 = fir.convert %2 : (f128) -> f128
  %c0 = arith.constant 0 : i32
  %4 = fir.insert_value %1, %3, [0 : i32] : (complex<f128>, f128) -> complex<f128>
  %c1 = arith.constant 1 : i32
  %5 = arith.constant -42.0 : f128
  %6 = fir.insert_value %4, %5, [1 : i32] : (complex<f128>, f128) -> complex<f128>
  return %6 : complex<f128>
}

// Test that we rewrite the signature of a func.function that accepts a complex<16>.
func.func private @paramcomplex16(complex<f128>) -> ()

// Test that we rewrite calls to func.functions that return or accept complex<16>.
func.func @callcomplex16() {
  %1 = fir.call @returncomplex16() : () -> complex<f128>
  fir.call @paramcomplex16(%1) : (complex<f128>) -> ()
  return
}

// Test multiple complex<16> parameters and arguments
func.func private @calleemultipleparamscomplex16(complex<f128>, complex<f128>, complex<f128>) -> ()

func.func @multipleparamscomplex16(%z1 : complex<f128>, %z2 : complex<f128>, %z3 : complex<f128>) {
  fir.call @calleemultipleparamscomplex16(%z1, %z2, %z3) : (complex<f128>, complex<f128>, complex<f128>) -> ()
  return
}

// Test that we rewrite the signature of and calls to a func.function that accepts
// and returns MLIR complex<f128>.
func.func private @mlircomplexf128(%z1: complex<f128>, %z2: complex<f128>) -> complex<f128> {
  %0 = fir.call @mlircomplexf128(%z1, %z2) : (complex<f128>, complex<f128>) -> complex<f128>
  return %0 : complex<f128>
}

// Test that we rewrite the fir.address_of operator.
func.func @addrof() {
  %r = fir.address_of(@returncomplex16) : () -> complex<f128>
  %p = fir.address_of(@paramcomplex16) : (complex<f128>) -> ()
  return
}

// CHECK-LABEL:   func.func @returncomplex16(
// CHECK-SAME:      %[[VAL_0:.*]]: !fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.sret = tuple<f128, f128>}) {
// CHECK:           %[[VAL_1:.*]] = fir.undefined complex<f128>
// CHECK:           %[[VAL_2:.*]] = arith.constant 2.000000e+00 : f128
// CHECK:           %[[VAL_3:.*]] = fir.convert %[[VAL_2]] : (f128) -> f128
// CHECK:           %[[VAL_4:.*]] = arith.constant 0 : i32
// CHECK:           %[[VAL_5:.*]] = fir.insert_value %[[VAL_1]], %[[VAL_3]], [0 : i32] : (complex<f128>, f128) -> complex<f128>
// CHECK:           %[[VAL_6:.*]] = arith.constant 1 : i32
// CHECK:           %[[VAL_7:.*]] = arith.constant -4.200000e+01 : f128
// CHECK:           %[[VAL_8:.*]] = fir.insert_value %[[VAL_5]], %[[VAL_7]], [1 : i32] : (complex<f128>, f128) -> complex<f128>
// CHECK:           %[[VAL_9:.*]] = fir.convert %[[VAL_0]] : (!fir.ref<tuple<f128, f128>>) -> !fir.ref<complex<f128>>
// CHECK:           fir.store %[[VAL_8]] to %[[VAL_9]] : !fir.ref<complex<f128>>
// CHECK:           return
// CHECK:         }
// CHECK:         func.func private @paramcomplex16(!fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.byval = tuple<f128, f128>})

// CHECK-LABEL:   func.func @callcomplex16() {
// CHECK:           %[[VAL_0:.*]] = llvm.intr.stacksave : !llvm.ptr
// CHECK:           %[[VAL_1:.*]] = fir.alloca tuple<f128, f128>
// CHECK:           fir.call @returncomplex16(%[[VAL_1]]) : (!fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.sret = tuple<f128, f128>}) -> ()
// CHECK:           %[[VAL_2:.*]] = fir.convert %[[VAL_1]] : (!fir.ref<tuple<f128, f128>>) -> !fir.ref<complex<f128>>
// CHECK:           %[[VAL_3:.*]] = fir.load %[[VAL_2]] : !fir.ref<complex<f128>>
// CHECK:           llvm.intr.stackrestore %[[VAL_0]] : !llvm.ptr
// CHECK:           %[[VAL_4:.*]] = llvm.intr.stacksave : !llvm.ptr
// CHECK:           %[[VAL_5:.*]] = fir.alloca complex<f128>
// CHECK:           fir.store %[[VAL_3]] to %[[VAL_5]] : !fir.ref<complex<f128>>
// CHECK:           %[[VAL_6:.*]] = fir.convert %[[VAL_5]] : (!fir.ref<complex<f128>>) -> !fir.ref<tuple<f128, f128>>
// CHECK:           fir.call @paramcomplex16(%[[VAL_6]]) : (!fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.byval = tuple<f128, f128>}) -> ()
// CHECK:           llvm.intr.stackrestore %[[VAL_4]] : !llvm.ptr
// CHECK:           return
// CHECK:         }
// CHECK:         func.func private @calleemultipleparamscomplex16(!fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.byval = tuple<f128, f128>}, !fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.byval = tuple<f128, f128>}, !fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.byval = tuple<f128, f128>})

// CHECK-LABEL:   func.func @multipleparamscomplex16(
// CHECK-SAME:      %[[VAL_0:.*]]: !fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.byval = tuple<f128, f128>}, %[[VAL_1:.*]]: !fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.byval = tuple<f128, f128>}, %[[VAL_2:.*]]: !fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.byval = tuple<f128, f128>}) {
// CHECK:           %[[VAL_3:.*]] = fir.convert %[[VAL_2]] : (!fir.ref<tuple<f128, f128>>) -> !fir.ref<complex<f128>>
// CHECK:           %[[VAL_4:.*]] = fir.load %[[VAL_3]] : !fir.ref<complex<f128>>
// CHECK:           %[[VAL_5:.*]] = fir.convert %[[VAL_1]] : (!fir.ref<tuple<f128, f128>>) -> !fir.ref<complex<f128>>
// CHECK:           %[[VAL_6:.*]] = fir.load %[[VAL_5]] : !fir.ref<complex<f128>>
// CHECK:           %[[VAL_7:.*]] = fir.convert %[[VAL_0]] : (!fir.ref<tuple<f128, f128>>) -> !fir.ref<complex<f128>>
// CHECK:           %[[VAL_8:.*]] = fir.load %[[VAL_7]] : !fir.ref<complex<f128>>
// CHECK:           %[[VAL_9:.*]] = llvm.intr.stacksave : !llvm.ptr
// CHECK:           %[[VAL_10:.*]] = fir.alloca complex<f128>
// CHECK:           fir.store %[[VAL_8]] to %[[VAL_10]] : !fir.ref<complex<f128>>
// CHECK:           %[[VAL_11:.*]] = fir.convert %[[VAL_10]] : (!fir.ref<complex<f128>>) -> !fir.ref<tuple<f128, f128>>
// CHECK:           %[[VAL_12:.*]] = fir.alloca complex<f128>
// CHECK:           fir.store %[[VAL_6]] to %[[VAL_12]] : !fir.ref<complex<f128>>
// CHECK:           %[[VAL_13:.*]] = fir.convert %[[VAL_12]] : (!fir.ref<complex<f128>>) -> !fir.ref<tuple<f128, f128>>
// CHECK:           %[[VAL_14:.*]] = fir.alloca complex<f128>
// CHECK:           fir.store %[[VAL_4]] to %[[VAL_14]] : !fir.ref<complex<f128>>
// CHECK:           %[[VAL_15:.*]] = fir.convert %[[VAL_14]] : (!fir.ref<complex<f128>>) -> !fir.ref<tuple<f128, f128>>
// CHECK:           fir.call @calleemultipleparamscomplex16(%[[VAL_11]], %[[VAL_13]], %[[VAL_15]]) : (!fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.byval = tuple<f128, f128>}, !fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.byval = tuple<f128, f128>}, !fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.byval = tuple<f128, f128>}) -> ()
// CHECK:           llvm.intr.stackrestore %[[VAL_9]] : !llvm.ptr
// CHECK:           return
// CHECK:         }

// CHECK-LABEL:   func.func private @mlircomplexf128(
// CHECK-SAME:      %[[VAL_0:.*]]: !fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.sret = tuple<f128, f128>}, %[[VAL_1:.*]]: !fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.byval = tuple<f128, f128>}, %[[VAL_2:.*]]: !fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.byval = tuple<f128, f128>}) {
// CHECK:           %[[VAL_3:.*]] = fir.convert %[[VAL_2]] : (!fir.ref<tuple<f128, f128>>) -> !fir.ref<complex<f128>>
// CHECK:           %[[VAL_4:.*]] = fir.load %[[VAL_3]] : !fir.ref<complex<f128>>
// CHECK:           %[[VAL_5:.*]] = fir.convert %[[VAL_1]] : (!fir.ref<tuple<f128, f128>>) -> !fir.ref<complex<f128>>
// CHECK:           %[[VAL_6:.*]] = fir.load %[[VAL_5]] : !fir.ref<complex<f128>>
// CHECK:           %[[VAL_7:.*]] = llvm.intr.stacksave : !llvm.ptr
// CHECK:           %[[VAL_8:.*]] = fir.alloca tuple<f128, f128>
// CHECK:           %[[VAL_9:.*]] = fir.alloca complex<f128>
// CHECK:           fir.store %[[VAL_6]] to %[[VAL_9]] : !fir.ref<complex<f128>>
// CHECK:           %[[VAL_10:.*]] = fir.convert %[[VAL_9]] : (!fir.ref<complex<f128>>) -> !fir.ref<tuple<f128, f128>>
// CHECK:           %[[VAL_11:.*]] = fir.alloca complex<f128>
// CHECK:           fir.store %[[VAL_4]] to %[[VAL_11]] : !fir.ref<complex<f128>>
// CHECK:           %[[VAL_12:.*]] = fir.convert %[[VAL_11]] : (!fir.ref<complex<f128>>) -> !fir.ref<tuple<f128, f128>>
// CHECK:           fir.call @mlircomplexf128(%[[VAL_8]], %[[VAL_10]], %[[VAL_12]]) : (!fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.sret = tuple<f128, f128>}, !fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.byval = tuple<f128, f128>}, !fir.ref<tuple<f128, f128>> {llvm.align = 16 : i32, llvm.byval = tuple<f128, f128>}) -> ()
// CHECK:           %[[VAL_13:.*]] = fir.convert %[[VAL_8]] : (!fir.ref<tuple<f128, f128>>) -> !fir.ref<complex<f128>>
// CHECK:           %[[VAL_14:.*]] = fir.load %[[VAL_13]] : !fir.ref<complex<f128>>
// CHECK:           llvm.intr.stackrestore %[[VAL_7]] : !llvm.ptr
// CHECK:           %[[VAL_15:.*]] = fir.convert %[[VAL_0]] : (!fir.ref<tuple<f128, f128>>) -> !fir.ref<complex<f128>>
// CHECK:           fir.store %[[VAL_14]] to %[[VAL_15]] : !fir.ref<complex<f128>>
// CHECK:           return
// CHECK:         }

// CHECK-LABEL:   func.func @addrof() {
// CHECK:           %[[VAL_0:.*]] = fir.address_of(@returncomplex16) : (!fir.ref<tuple<f128, f128>>) -> ()
// CHECK:           %[[VAL_1:.*]] = fir.address_of(@paramcomplex16) : (!fir.ref<tuple<f128, f128>>) -> ()
// CHECK:           return
// CHECK:         }
