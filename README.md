# lsl2beta

#### 20170420
>(try9)</p>
1. 修改.get_tab_cal 與 .get_var_cal

#### 20170419
>(try9)</p>
1. 增加summary method，可以選擇aic/bic，若相等選擇delta最大者，若相等選gammay最大者。

#### 20170418
>(try8)</p>
1. 更正par和df算法

#### 20170414
>(try8)</p>
1. 修改多組時df算法
2. 增加.get_val_cal函數
3. 細微的修改

#### 20170413
>(try8)</p>
1. 更改名稱
2. 修改排版（使用Rstudio reformat功能）
3. 刪除.threshold函數，併入.shrinkage_cal

#### 20170412
>(try7)</p>
1. 加入各種適配度指標，在只有一組時為正確。

#### 20170410
>(try7)</p>
1. 修改.dml_cal的input部分
2. 修改.ecm的output
3. 修改$model的內容

#### 20170407
>(try7)</p>
1. 修改參數個數的算法
2. 修改get_par函數
3. alpha起始值影響是否可以順利迭代，演算法本身應該沒有問題。

#### 20170331
>(try7)</p>
1. 修改knowledge的格式（由array轉換為list)
2. learn的ecm算法由double loop改成lapply（但速度沒有變快）
3. 修改alpha的起始值（alpha_r為ref_group的平均，alpha_i第一組為0，其他組為跟ref_group的差值）

#### 20170330
>(try7)</p>
1. reference class可使用
2. 修正dml的算法
>(try6)</p>
1. 更改多個gamma與delta的ecm的output的排法

#### 20170329
>(try6)</p>
1. 更動matgen函式：將alpha_r初始值改為mu_eta[[1]]，否則"可能"出現無法無法取反函數的情況

#### 20170328
>(try6)</p>
1. ecm函式可相容目前架構

#### 20170323
>(try6)</p>

1. invspecify簡易完成，可將參數表轉換為矩陣。但需注意phi矩陣僅有上三角

#### 20170322
>(try6)</p>

1. specify簡易完成
2. 挑選phi只取上/下三角的功能放置於specify中
3. 刪除betagen函數
4. 修改matgen函數：更改輸入格式，改為beta_vf等等

#### 20170321
>(try6)</p>

1. 修正getpar函數
2. 修正matgen函數


#### 20170315
>(try6)</p>

1. 修正import函數 

#### 20170314
>(try6)</p>

1. 修正import函數

#### 20170313
>(try6)</p>

1. 修正import函數
2. 排版美編修正

#### 20170310
>(try6)</p>

1. 修正import函數


#### 20170309
>(try6)</p>

1. 亦可以變數名稱作為improt中的"var_group"指標
2. 製作getpar函數，可將參數取出，但此部分忽略phi只取上/下三角，待修正

#### 20170308
>(try6)</p>

1. import初步建置

#### 20170307
>(try5)</p>

1. 將ecm製作成function
2. 更新multi-groups的dml

#### 20170306
>(try5)</p>

1. 更改變數名稱

#### 20170303
>(try4)</p>
1. multi-groups在此架構可正確使用

#### 20170224
1. single group在新架構可正確使用

#### 20170220
1. 修正變數名稱
2. 將increment component改成list

#### 20170215
1. 修正e_step中的C_vv算法

#### 20170210
1. 修正update的錯誤= =
2. Beta的t1 penalty測試OK

#### 20170209
1. 找出Phi矩陣不對稱的原因：許多細微的過度向量化XD
2. 排版美編修正

#### 20170208
1. 使weight_Phi於每次Phi更新後重新計算
2. 使C_zetatildazeta與C_zetatildazetatildam於每次Phi更新後重新計算
3. 加入colnames/rownames/names，潛在變項以f表示，觀察變項以v表示
