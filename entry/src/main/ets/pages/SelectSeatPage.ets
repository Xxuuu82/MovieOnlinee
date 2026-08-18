import { HallSeat, SeatRow, Seat } from '../model/HallSeat';
import { Schedule } from '../model/Schedule';
import { Order } from '../model/Order';
import { UserAccount } from '../model/UserAccount';
import HttpUtil from '../http/HttpUtil';
import { HttpResponseResult } from '../model/HttpResponseResult';


// =========================================================
// 创建订单请求参数
// ArkTS 必须使用明确声明的接口，不能直接使用 Object
// =========================================================
interface CreateOrderRequest {
  scheduleId: number;
  seats: string;
  amount: number;
  totalPrice: number;
  userId: number;
}


@Entry
@Component
struct SelectSeatPage {

  // =========================================================
  // 当前排片 ID
  // =========================================================

  @State scheduleId: number = 0;


  // =========================================================
  // 当前登录用户
  //
  // LoginPage 登录成功后会把用户信息
  // 写入 AppStorage 的 userAccount 键
  // =========================================================

  @StorageLink('userAccount')
  userAccount: UserAccount | null = null;


  // =========================================================
  // 当前排片信息
  // =========================================================

  @State schedule: Schedule | null = null;


  // =========================================================
  // 当前影厅座位布局
  //
  // 完全由后端接口返回
  //
  // 不写死：
  // - 几排
  // - 每排几个座位
  // =========================================================

  @State hallSeat: HallSeat | null = null;


  // =========================================================
  // 当前已经选择的座位
  //
  // 保存 seatCode
  //
  // 例如：
  //
  // [
  //   "4 排-04 座",
  //   "4 排-05 座"
  // ]
  // =========================================================

  @State selectedSeats: string[] = [];


  // =========================================================
  // 页面加载状态
  // =========================================================

  @State isLoading: boolean = true;


  // =========================================================
  // 创建订单状态
  // 防止用户连续点击购票
  // =========================================================

  @State isCreatingOrder: boolean = false;


  // =========================================================
  // 生命周期
  // =========================================================

  aboutToAppear(): void {

    const params: Record<string, Object> =
      this.getUIContext()
        .getRouter()
        .getParams() as Record<string, Object>;

    this.scheduleId =
      (params?.scheduleId as number) ?? 0;


    console.info(
      '进入选座页面:',
      'scheduleId =',
      this.scheduleId
    );


    if (this.scheduleId <= 0) {

      this.showToast(
        '没有获取到排片信息'
      );

      this.isLoading = false;

      return;
    }


    this.loadPageData();
  }


  // =========================================================
  // 加载页面全部数据
  // =========================================================

  async loadPageData(): Promise<void> {

    this.isLoading = true;

    try {

      // -----------------------------------------------------
      // 1. 获取排片详情
      // -----------------------------------------------------

      await this.loadSchedule();


      // -----------------------------------------------------
      // 2. 排片获取成功后，根据 hallId 获取座位
      // -----------------------------------------------------

      if (this.schedule) {

        if (this.schedule.hallId <= 0) {

          this.showToast(
            '当前排片没有对应影厅'
          );

          return;
        }


        await this.loadHallSeats(
          this.schedule.hallId
        );
      }

    } catch (error) {

      console.error(
        '加载选座页面失败:',
        error
      );

      this.showToast(
        '页面加载失败，请稍后重试'
      );

    } finally {

      this.isLoading = false;
    }
  }


  // =========================================================
  // 获取排片详情
  //
  // API：
  // /user/schedule/detail?scheduleId={scheduleId}
  // =========================================================

  async loadSchedule(): Promise<void> {

    try {

      console.info(
        '获取排片详情:',
        this.scheduleId
      );


      const response:
        HttpResponseResult<Schedule> =
        await HttpUtil.get<
        HttpResponseResult<Schedule>
        >(
          `/user/schedule/detail?scheduleId=${this.scheduleId}`
        );


      if (
        response.code === 200 &&
          response.data
      ) {

        this.schedule =
          response.data;


        console.info(
          '排片获取成功:',
          JSON.stringify(
            this.schedule
          )
        );

      } else {

        console.error(
          '获取排片失败:',
          response.message
        );


        this.showToast(
          response.message ||
            '获取排片失败'
        );
      }

    } catch (error) {

      console.error(
        '请求排片异常:',
        error
      );


      this.showToast(
        '获取排片失败'
      );
    }
  }


  // =========================================================
  // 获取影厅座位布局
  //
  // API：
  // /user/schedule/seat-layout
  // ?scheduleId={scheduleId}
  // &hallId={hallId}
  //
  // 后端返回：
  //
  // rowCount
  // colCount
  // seatRows
  //     rowIndex
  //     rowName
  //     seats
  //         colIndex
  //         seatCode
  //         status
  //
  // 因此前端完全动态渲染
  // =========================================================

  async loadHallSeats(
    hallId: number
  ): Promise<void> {

    try {

      console.info(
        '获取座位布局:',
        'scheduleId =',
        this.scheduleId,
        'hallId =',
        hallId
      );


      const response:
        HttpResponseResult<HallSeat> =
        await HttpUtil.get<
        HttpResponseResult<HallSeat>
        >(
          `/user/schedule/seat-layout?scheduleId=${this.scheduleId}&hallId=${hallId}`
        );


      if (
        response.code === 200 &&
          response.data
      ) {

        this.hallSeat =
          response.data;


        console.info(
          '座位布局获取成功:',
          JSON.stringify(
            this.hallSeat
          )
        );

      } else {

        console.error(
          '获取座位布局失败:',
          response.message
        );


        this.showToast(
          response.message ||
            '获取座位信息失败'
        );
      }

    } catch (error) {

      console.error(
        '请求座位布局异常:',
        error
      );


      this.showToast(
        '获取座位信息失败'
      );
    }
  }


  // =========================================================
  // 判断座位是否已经被选择
  // =========================================================

  isSeatSelected(
    seatCode: string
  ): boolean {

    return this.selectedSeats.indexOf(
      seatCode
    ) >= 0;
  }


  // =========================================================
  // 点击座位
  //
  // status：
  //
  // 0 = 可用
  // 1 = 已占用
  //
  // 已占用座位不能点击
  //
  // 已选座位再次点击 → 取消选择
  // =========================================================

  toggleSeat(
    seat: Seat
  ): void {

    // -------------------------------------------------------
    // 已占用座位不能选择
    // -------------------------------------------------------

    if (seat.status === 1) {
      return;
    }


    const seatCode: string =
      seat.seatCode;


    const index: number =
      this.selectedSeats.indexOf(
        seatCode
      );


    // -------------------------------------------------------
    // 已经选中
    // 再次点击 → 取消
    // -------------------------------------------------------

    if (index >= 0) {

      this.selectedSeats =
        this.selectedSeats.filter(
          (code: string) =>
          code !== seatCode
        );


      console.info(
        '取消选座:',
        seatCode
      );


      return;
    }


    // -------------------------------------------------------
    // 当前未选择
    // 点击 → 加入已选座位
    // -------------------------------------------------------

    this.selectedSeats = [
      ...this.selectedSeats,
      seatCode
    ];


    console.info(
      '选择座位:',
      seatCode
    );
  }


  // =========================================================
  // 点击已选座位右上角 ×
  //
  // 取消选座
  // =========================================================

  removeSelectedSeat(
    seatCode: string
  ): void {

    this.selectedSeats =
      this.selectedSeats.filter(
        (code: string) =>
        code !== seatCode
      );


    console.info(
      '通过 × 取消座位:',
      seatCode
    );
  }


  // =========================================================
  // 获取已选座位数量
  // =========================================================

  getSeatCount(): number {

    return this.selectedSeats.length;
  }


  // =========================================================
  // 获取当前电影票单价
  //
  // Schedule.price
  // =========================================================

  getUnitPrice(): number {

    if (!this.schedule) {
      return 0;
    }


    return Number(
      this.schedule.price
    ) || 0;
  }


  // =========================================================
  // 计算总金额
  // =========================================================

  getTotalPrice(): number {

    return this.getUnitPrice() *
      this.getSeatCount();
  }


  // =========================================================
  // 格式化总金额
  // =========================================================

  getTotalPriceText(): string {

    return this.getTotalPrice()
      .toFixed(2);
  }


  // =========================================================
  // 格式化日期
  // =========================================================

  formatDate(
    showTime: string
  ): string {

    if (!showTime) {
      return '';
    }


    const parts: string[] =
      showTime.split('T');


    if (parts.length !== 2) {
      return showTime;
    }


    const dateParts: string[] =
      parts[0].split('-');


    if (dateParts.length !== 3) {
      return showTime;
    }


    const month: number =
      Number(dateParts[1]);


    const day: number =
      Number(dateParts[2]);


    return `${month}月${day}日`;
  }


  // =========================================================
  // 格式化时间
  // =========================================================

  formatTime(
    showTime: string
  ): string {

    if (!showTime) {
      return '--:--';
    }


    const parts: string[] =
      showTime.split('T');


    if (parts.length !== 2) {
      return '--:--';
    }


    const timeParts: string[] =
      parts[1].split(':');


    if (timeParts.length < 2) {
      return '--:--';
    }


    return `${timeParts[0]}:${timeParts[1]}`;
  }


  // =========================================================
  // 计算结束时间
  // =========================================================

  getEndTime(): string {

    if (!this.schedule) {
      return '--:--';
    }


    const showTime: string =
      this.schedule.showTime;


    const duration: number =
      Number(
        this.schedule.movieDuration
      ) || 0;


    if (
      !showTime ||
        duration <= 0
    ) {

      return '--:--';
    }


    const parts: string[] =
      showTime.split('T');


    if (parts.length !== 2) {
      return '--:--';
    }


    const timeParts: string[] =
      parts[1].split(':');


    if (timeParts.length < 2) {
      return '--:--';
    }


    let hour: number =
      Number(timeParts[0]);


    let minute: number =
      Number(timeParts[1]);


    minute += duration;


    hour +=
    Math.floor(
      minute / 60
    );


    minute =
      minute % 60;


    hour =
      hour % 24;


    return `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
  }


  // =========================================================
  // 创建订单
  //
  // API：
  //
  // POST /user/order/create
  //
  // 请求参数：
  //
  // scheduleId
  // seats
  // amount
  // totalPrice
  // userId
  //
  // paymentMethod 是可选参数，
  // 支付方式由后面的 OrderPaymentPage 负责。
  // =========================================================

  async createOrder(): Promise<void> {

    // -------------------------------------------------------
    // 防止重复点击
    // -------------------------------------------------------

    if (this.isCreatingOrder) {
      return;
    }


    // -------------------------------------------------------
    // 登录校验
    //
    // 未登录 → 提示并跳转登录页
    //
    // LoginPage 登录成功后调用 router.back()，
    // 会回到本页，已选座位仍然保留，
    // 用户再次点击购票即可
    // -------------------------------------------------------

    const userAccount: UserAccount | null =
      this.userAccount;


    if (
      !userAccount ||
        userAccount.id <= 0
    ) {

      this.showToast(
        '请先登录'
      );


      this.goToLoginPage();


      return;
    }


    // -------------------------------------------------------
    // 当前登录用户 ID
    // -------------------------------------------------------

    const userId: number =
      userAccount.id;


    // -------------------------------------------------------
    // 检查排片
    // -------------------------------------------------------

    if (!this.schedule) {

      this.showToast(
        '排片信息还没有加载完成'
      );

      return;
    }


    // -------------------------------------------------------
    // 检查座位
    // -------------------------------------------------------

    if (
      this.selectedSeats.length === 0
    ) {

      this.showToast(
        '请先选择座位'
      );

      return;
    }


    // -------------------------------------------------------
    // 创建订单请求参数
    //
    // 必须使用明确声明的 CreateOrderRequest
    // 不能写成 Object
    // -------------------------------------------------------

    const requestData:
      CreateOrderRequest = {

      scheduleId:
      this.scheduleId,

      seats:
      this.selectedSeats.join(','),

      amount:
      this.selectedSeats.length,

      totalPrice:
      this.getTotalPrice(),

      userId:
      userId
    };


    console.info(
      '创建订单参数:',
      JSON.stringify(
        requestData
      )
    );


    this.isCreatingOrder = true;


    try {

      // -----------------------------------------------------
      // 调用创建订单接口
      // -----------------------------------------------------

      const response:
        HttpResponseResult<Order> =
        await HttpUtil.post<
        HttpResponseResult<Order>
        >(
          '/user/order/create',
          requestData
        );


      // -----------------------------------------------------
      // 创建成功
      // -----------------------------------------------------

      if (
        response.code === 200 &&
          response.data
      ) {

        const order: Order =
          response.data;


        console.info(
          '订单创建成功:',
          JSON.stringify(
            order
          )
        );


        console.info(
          '订单 ID:',
          order.id
        );


        // ---------------------------------------------------
        // 跳转订单支付页面
        // ---------------------------------------------------

        this.goToPayPage(
          order.id
        );

      } else {

        console.error(
          '创建订单失败:',
          response.message
        );


        this.showToast(
          response.message ||
            '创建订单失败'
        );
      }

    } catch (error) {

      console.error(
        '创建订单异常:',
        error
      );


      this.showToast(
        '创建订单失败，请稍后重试'
      );

    } finally {

      this.isCreatingOrder = false;
    }
  }


  // =========================================================
  // 跳转登录页
  // =========================================================

  goToLoginPage(): void {

    this.getUIContext()
      .getRouter()
      .pushUrl({
        url: 'pages/LoginPage'
      });
  }


  // =========================================================
  // 跳转订单支付页面
  // =========================================================

  goToPayPage(
    orderId: number
  ): void {

    this.getUIContext()
      .getRouter()
      .pushUrl({
        url: 'pages/PaymentPage',
        params: {
          orderId: orderId,
        }
      });
  }


  // =========================================================
  // 返回上一页
  // =========================================================

  goBack(): void {

    this.getUIContext()
      .getRouter()
      .back();
  }


  // =========================================================
  // Toast
  // =========================================================

  showToast(
    message: string
  ): void {

    this.getUIContext()
      .getPromptAction()
      .showToast({
        message: message
      });
  }


  // =========================================================
  // 获取座位编号
  //
  // API 返回：
  //
  // "4 排-04 座"
  //
  // 页面只显示：
  //
  // "04 座"
  // =========================================================

  getSeatNumber(
    seatCode: string
  ): string {

    if (!seatCode) {
      return '';
    }


    const index: number =
      seatCode.lastIndexOf('-');


    if (index < 0) {
      return seatCode;
    }


    return seatCode.substring(
      index + 1
    );
  }


  // =========================================================
  // 构建单个座位
  // =========================================================

  @Builder
  buildSeat(
    seat: Seat
  ) {

    Column() {

      Text(
        this.getSeatNumber(
          seat.seatCode
        )
      )
        .fontSize(8)
        .fontColor(
          seat.status === 1
            ? '#999999'
            : this.isSeatSelected(
            seat.seatCode
          )
            ? '#FFFFFF'
            : '#666666'
        )
        .maxLines(1);

    }
    .width(28)
    .height(28)
    .justifyContent(
      FlexAlign.Center
    )
    .alignItems(
      HorizontalAlign.Center
    )
    .backgroundColor(
      seat.status === 1
        ? '#D9D9D9'
        : this.isSeatSelected(
        seat.seatCode
      )
        ? '#1698CE'
        : '#FFFFFF'
    )
    .border({
      width: 1,
      color:
      seat.status === 1
        ? '#CCCCCC'
        : this.isSeatSelected(
        seat.seatCode
      )
        ? '#1698CE'
        : '#B8B8B8'
    })
    .borderRadius(4)
    .onClick(() => {

      this.toggleSeat(
        seat
      );

    });
  }


  // =========================================================
  // 构建已选座位卡片
  // =========================================================

  @Builder
  buildSelectedSeat(
    seatCode: string
  ) {

    Stack() {

      Column() {

        Text(seatCode)
          .fontSize(13)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({
            overflow:
            TextOverflow.Ellipsis
          });


        Text(
          `¥${this.getUnitPrice().toFixed(2)}`
        )
          .fontSize(12)
          .fontColor('#777777')
          .margin({
            top: 4
          });

      }
      .width('100%')
      .height(62)
      .padding({
        left: 10,
        right: 10,
        top: 10,
        bottom: 8
      })
      .alignItems(
        HorizontalAlign.Start
      );


      // -------------------------------------------------------
      // 右上角 ×
      // -------------------------------------------------------

      Text('×')
        .fontSize(18)
        .fontColor('#666666')
        .width(22)
        .height(22)
        .textAlign(
          TextAlign.Center
        )
        .position({
          right: 0,
          top: 0
        })
        .onClick(() => {

          this.removeSelectedSeat(
            seatCode
          );

        });

    }
    .width(105)
    .height(62)
    .backgroundColor('#EEEEEE')
    .borderRadius(5)
    .margin({
      right: 8
    });
  }


  // =========================================================
  // 页面 UI
  // =========================================================

  build() {

    Column() {

      // =====================================================
      // 顶部导航栏
      // =====================================================

      Row() {

        SymbolGlyph(
          $r('sys.symbol.chevron_left')
        )
          .fontSize(24)
          .onClick(() => {

            this.goBack();

          });


        Text(
          this.schedule?.hallName ||
            '选择座位'
        )
          .fontSize(18)
          .fontWeight(
            FontWeight.Bold
          )
          .fontColor('#222222')
          .layoutWeight(1)
          .textAlign(
            TextAlign.Center
          )
          .margin({
            right: 24
          });

      }
      .width('100%')
      .height(44)
      .padding({
        left: 12,
        right: 12
      })
      .backgroundColor('#FFFFFF');


      // =====================================================
      // 页面加载
      // =====================================================

      if (this.isLoading) {

        Column() {

          LoadingProgress()
            .width(32)
            .height(32)
            .color('#1698CE');


          Text('正在加载座位...')
            .fontSize(13)
            .fontColor('#999999')
            .margin({
              top: 10
            });

        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(
          FlexAlign.Center
        )
        .alignItems(
          HorizontalAlign.Center
        );


      } else {

        // ===================================================
        // 页面主体
        // ===================================================

        Scroll() {

          Column() {

            // ===============================================
            // 电影 / 排片信息
            // ===============================================

            if (this.schedule) {

              Column() {

                Text(
                  this.schedule.movieName
                )
                  .fontSize(19)
                  .fontWeight(
                    FontWeight.Bold
                  )
                  .fontColor('#222222')
                  .margin({
                    bottom: 5
                  });


                Text(
                  `${this.formatDate(this.schedule.showTime)} ${this.formatTime(this.schedule.showTime)}-${this.getEndTime()}`
                )
                  .fontSize(13)
                  .fontColor('#777777');


                Text(
                  `${this.schedule.hallName} `
                )
                  .fontSize(13)
                  .fontColor('#999999')
                  .margin({
                    top: 4
                  });

              }
              .width('100%')
              .padding({
                left: 16,
                right: 16,
                top: 12,
                bottom: 8
              })
              .alignItems(
                HorizontalAlign.Start
              );
            }


            // ===============================================
            // 银幕
            // ===============================================

            Text('银幕中央')
              .fontSize(11)
              .fontColor('#999999')
              .width(170)
              .height(22)
              .textAlign(
                TextAlign.Center
              )
              .backgroundColor('#E9E9E9')
              .borderRadius(11)
              .margin({
                top: 6,
                bottom: 12
              });


            // ===============================================
            // 动态座位
            // ===============================================

            if (this.hallSeat) {

              Scroll() {

                Column() {

                  // -------------------------------------------
                  // 后端返回多少排，就显示多少排
                  // -------------------------------------------

                  ForEach(
                    this.hallSeat.seatRows,
                    (row: SeatRow) => {

                      Row() {

                        // -------------------------------------
                        // 排号
                        // -------------------------------------

                        Text(
                          row.rowName
                        )
                          .fontSize(11)
                          .fontColor('#777777')
                          .width(38)
                          .textAlign(
                            TextAlign.Center
                          );


                        // -------------------------------------
                        // 当前排座位
                        // -------------------------------------

                        Row({ space: 5 }) {

                          ForEach(
                            row.seats,
                            (seat: Seat) => {

                              this.buildSeat(
                                seat
                              );

                            },
                            (seat: Seat) =>
                            seat.seatCode
                          );

                        }

                      }
                      .height(34)
                      .justifyContent(
                        FlexAlign.Start
                      )
                      .margin({
                        bottom: 2
                      });

                    },
                    (row: SeatRow) =>
                    row.rowIndex.toString()
                  );

                }
                .padding({
                  left: 10,
                  right: 10,
                  top: 4,
                  bottom: 10
                });

              }
              .width('100%')
              .scrollable(
                ScrollDirection.Horizontal
              )
              .scrollBar(
                BarState.Off
              );


              // =============================================
              // 座位状态说明
              // =============================================

              Row({ space: 22 }) {

                // -------------------------------------------
                // 可选
                // -------------------------------------------

                Row() {

                  Column()
                    .width(18)
                    .height(18)
                    .backgroundColor('#FFFFFF')
                    .border({
                      width: 1,
                      color: '#B8B8B8'
                    })
                    .borderRadius(3);


                  Text('可选')
                    .fontSize(11)
                    .fontColor('#777777')
                    .margin({
                      left: 5
                    });

                }


                // -------------------------------------------
                // 已选
                // -------------------------------------------

                Row() {

                  Column()
                    .width(18)
                    .height(18)
                    .backgroundColor('#1698CE')
                    .borderRadius(3);


                  Text('已选')
                    .fontSize(11)
                    .fontColor('#777777')
                    .margin({
                      left: 5
                    });

                }


                // -------------------------------------------
                // 已售
                // -------------------------------------------

                Row() {

                  Column()
                    .width(18)
                    .height(18)
                    .backgroundColor('#D9D9D9')
                    .borderRadius(3);


                  Text('已售')
                    .fontSize(11)
                    .fontColor('#777777')
                    .margin({
                      left: 5
                    });

                }

              }
              .width('100%')
              .justifyContent(
                FlexAlign.Center
              )
              .margin({
                top: 5,
                bottom: 12
              });

            }


            // =================================================
            // 已选座位
            // =================================================

            if (
              this.selectedSeats.length > 0
            ) {

              Column() {

                Text('已选座位')
                  .fontSize(14)
                  .fontWeight(
                    FontWeight.Medium
                  )
                  .fontColor('#444444')
                  .width('100%')
                  .margin({
                    bottom: 7
                  });


                Scroll() {

                  Row() {

                    ForEach(
                      this.selectedSeats,
                      (seatCode: string) => {

                        this.buildSelectedSeat(
                          seatCode
                        );

                      },
                      (seatCode: string) =>
                      seatCode
                    );

                  }

                }
                .width('100%')
                .height(70)
                .scrollable(
                  ScrollDirection.Horizontal
                )
                .scrollBar(
                  BarState.Off
                );

              }
              .width('100%')
              .padding({
                left: 12,
                right: 12,
                top: 4,
                bottom: 10
              });

            }


            Blank()
              .height(12);

          }

        }
        .width('100%')
        .layoutWeight(1)
        .scrollable(
          ScrollDirection.Vertical
        )
        .scrollBar(
          BarState.Auto
        );


        // =====================================================
        // 底部购票栏
        // =====================================================

        Row() {

          Column() {

            Text(
              `已选 ${this.getSeatCount()} 个座位`
            )
              .fontSize(12)
              .fontColor('#777777');


            Row() {

              Text('总价 ')
                .fontSize(13)
                .fontColor('#666666');


              Text(
                `¥${this.getTotalPriceText()}`
              )
                .fontSize(19)
                .fontWeight(
                  FontWeight.Bold
                )
                .fontColor('#FF5533');

            }
            .margin({
              top: 3
            });

          }
          .layoutWeight(1)
          .alignItems(
            HorizontalAlign.Start
          )
          .margin({
            left: 16
          });


          // =================================================
          // 购票按钮
          // =================================================

          Button(
            this.isCreatingOrder
              ? '创建中'
              : '购票'
          )
            .width(78)
            .height(40)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor(
              this.selectedSeats.length > 0 &&
                !this.isCreatingOrder
                ? '#1698CE'
                : '#BBBBBB'
            )
            .borderRadius(20)
            .enabled(
              this.selectedSeats.length > 0 &&
                !this.isCreatingOrder
            )
            .margin({
              right: 14
            })
            .onClick(() => {

              this.createOrder();

            });

        }
        .width('100%')
        .height(68)
        .padding({
          top: 8,
          bottom: 8
        })
        .backgroundColor('#FFFFFF');

      }

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }
}