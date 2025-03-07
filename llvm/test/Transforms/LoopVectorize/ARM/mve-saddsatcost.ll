; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -passes=loop-vectorize,instcombine,simplifycfg < %s -S -o - | FileCheck %s --check-prefix=CHECK
; RUN: opt -passes=loop-vectorize -debug-only=loop-vectorize -disable-output < %s 2>&1 | FileCheck %s --check-prefix=CHECK-COST
; REQUIRES: asserts

target datalayout = "e-m:e-p:32:32-Fi8-i64:64-v128:64:128-a:0:32-n32-S64"
target triple = "thumbv8.1m.main-arm-none-eabi"

; CHECK-COST-LABEL: arm_offset_q15
; CHECK-COST: LV: Found an estimated cost of 2 for VF 1 For instruction:   %1 = tail call i16 @llvm.sadd.sat.i16(i16 %0, i16 %offset)
; CHECK-COST: Cost of 36 for VF 2: REPLICATE ir<%1> = call @llvm.sadd.sat.i16(ir<%0>, ir<%offset>)
; CHECK-COST: Cost of 8 for VF 4: WIDEN-INTRINSIC ir<%1> = call llvm.sadd.sat(ir<%0>, ir<%offset>)
; CHECK-COST: Cost of 2 for VF 8: WIDEN-INTRINSIC ir<%1> = call llvm.sadd.sat(ir<%0>, ir<%offset>)

define void @arm_offset_q15(ptr nocapture readonly %pSrc, i16 signext %offset, ptr nocapture noalias %pDst, i32 %blockSize) #0 {
; CHECK-LABEL: @arm_offset_q15(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP_NOT6:%.*]] = icmp eq i32 [[BLOCKSIZE:%.*]], 0
; CHECK-NEXT:    br i1 [[CMP_NOT6]], label [[WHILE_END:%.*]], label [[VECTOR_PH:%.*]]
; CHECK:       vector.ph:
; CHECK-NEXT:    [[N_RND_UP:%.*]] = add i32 [[BLOCKSIZE]], 7
; CHECK-NEXT:    [[N_VEC:%.*]] = and i32 [[N_RND_UP]], -8
; CHECK-NEXT:    [[BROADCAST_SPLATINSERT7:%.*]] = insertelement <8 x i16> poison, i16 [[OFFSET:%.*]], i64 0
; CHECK-NEXT:    [[BROADCAST_SPLAT8:%.*]] = shufflevector <8 x i16> [[BROADCAST_SPLATINSERT7]], <8 x i16> poison, <8 x i32> zeroinitializer
; CHECK-NEXT:    br label [[VECTOR_BODY:%.*]]
; CHECK:       vector.body:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i32 [ 0, [[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], [[VECTOR_BODY]] ]
; CHECK-NEXT:    [[OFFSET_IDX:%.*]] = shl i32 [[INDEX]], 1
; CHECK-NEXT:    [[NEXT_GEP:%.*]] = getelementptr i8, ptr [[PSRC:%.*]], i32 [[OFFSET_IDX]]
; CHECK-NEXT:    [[OFFSET_IDX5:%.*]] = shl i32 [[INDEX]], 1
; CHECK-NEXT:    [[NEXT_GEP6:%.*]] = getelementptr i8, ptr [[PDST:%.*]], i32 [[OFFSET_IDX5]]
; CHECK-NEXT:    [[ACTIVE_LANE_MASK:%.*]] = call <8 x i1> @llvm.get.active.lane.mask.v8i1.i32(i32 [[INDEX]], i32 [[BLOCKSIZE]])
; CHECK-NEXT:    [[WIDE_MASKED_LOAD:%.*]] = call <8 x i16> @llvm.masked.load.v8i16.p0(ptr [[NEXT_GEP]], i32 2, <8 x i1> [[ACTIVE_LANE_MASK]], <8 x i16> poison)
; CHECK-NEXT:    [[TMP0:%.*]] = call <8 x i16> @llvm.sadd.sat.v8i16(<8 x i16> [[WIDE_MASKED_LOAD]], <8 x i16> [[BROADCAST_SPLAT8]])
; CHECK-NEXT:    call void @llvm.masked.store.v8i16.p0(<8 x i16> [[TMP0]], ptr [[NEXT_GEP6]], i32 2, <8 x i1> [[ACTIVE_LANE_MASK]])
; CHECK-NEXT:    [[INDEX_NEXT]] = add i32 [[INDEX]], 8
; CHECK-NEXT:    [[TMP1:%.*]] = icmp eq i32 [[INDEX_NEXT]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[TMP1]], label [[WHILE_END]], label [[VECTOR_BODY]], !llvm.loop [[LOOP0:![0-9]+]]
; CHECK:       while.end:
; CHECK-NEXT:    ret void
;
entry:
  %cmp.not6 = icmp eq i32 %blockSize, 0
  br i1 %cmp.not6, label %while.end, label %while.body

while.body:                                       ; preds = %entry, %while.body
  %blkCnt.09 = phi i32 [ %dec, %while.body ], [ %blockSize, %entry ]
  %pSrc.addr.08 = phi ptr [ %incdec.ptr, %while.body ], [ %pSrc, %entry ]
  %pDst.addr.07 = phi ptr [ %incdec.ptr3, %while.body ], [ %pDst, %entry ]
  %incdec.ptr = getelementptr inbounds i16, ptr %pSrc.addr.08, i32 1
  %0 = load i16, ptr %pSrc.addr.08, align 2
  %1 = tail call i16 @llvm.sadd.sat.i16(i16 %0, i16 %offset)
  %incdec.ptr3 = getelementptr inbounds i16, ptr %pDst.addr.07, i32 1
  store i16 %1, ptr %pDst.addr.07, align 2
  %dec = add i32 %blkCnt.09, -1
  %cmp.not = icmp eq i32 %dec, 0
  br i1 %cmp.not, label %while.end, label %while.body

while.end:                                        ; preds = %while.body, %entry
  ret void
}

declare i16 @llvm.sadd.sat.i16(i16, i16)

attributes #0 = { "target-features"="+mve" }
;; NOTE: These prefixes are unused and the list is autogenerated. Do not add tests below this line:
; CHECK-COST: {{.*}}
