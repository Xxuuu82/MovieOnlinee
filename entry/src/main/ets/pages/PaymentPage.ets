
import HttpUtil from '../http/HttpUtil';
import promptAction from '@ohos.promptAction';
import { HttpResponseResult } from '../model/HttpResponseResult';
import { Order } from '../model/Order';
import { UserAccount, UserBalance } from '../model/UserAccount';
import { Schedule } from '../model/Schedule';
import { Movie } from '../model/Movie';

// 支付方式枚举
enum PaymentMethod {
  BALANCE = 'balance',
  ALIPAY = 'alipay',
  WECHAT = 'wechat'
}

// 支付方式配置
interface PaymentOption {
  key: PaymentMethod;
  label: string;
  iconText: string;
  iconColor: string;
}

// 支付接口响应数据
interface PayResult {
  orderNo: string;
  orderId: number;
  qrCodeContent: string;
}

@Entry
@Component
struct PaymentPage {
  // 订单信息
  @State orderId: number = 0;
  @State order: Order | null = null;
  @State schedule: Schedule | null = null;
  @State movie: Movie | null = null;

  // 支付相关
  @State selectedMethod: PaymentMethod = PaymentMethod.BALANCE;
  @State isPaying: boolean = false;
  @State remainingBalance: number = 0; // 账户余额

  @StorageLink("userAccount")
  userAccount: UserAccount | null = null;

  // 支付方式列表
  private paymentOptions: PaymentOption[] = [
    { key: PaymentMethod.BALANCE, label: '余额支付', iconText: '余', iconColor: '#FF9800' },
    { key: PaymentMethod.ALIPAY, label: '支付宝支付', iconText: '支', iconColor: '#1677FF' },
    { key: PaymentMethod.WECHAT, label: '微信支付', iconText: '微', iconColor: '#07C160' }
  ];

  async aboutToAppear(): Promise<void> {
    // 获取传递的参数
    const params: ESObject = this.getUIContext().getRouter().getParams();
    this.orderId = params?.orderId ?? 0;

    // 查询账户余额
    this.getBalance()

    // 加载订单详情
    await this.loadOrderDetail();
  }

  // 查询账户余额
  async getBalance() {
    try {
      const response = await HttpUtil.get<HttpResponseResult<UserBalance>>(
        `/user/balance/info?userId=${this.userAccount?.id ?? 0}`
      );
      if (response.code === 200 && response.data) {
        this.remainingBalance = response.data.balance;
      }
    } catch (error) {
      console.error('获取余额失败:', error);
    }
  }

  // 加载订单详情
  async loadOrderDetail(): Promise<void> {
    try {
      // 获取订单详情
      const orderResponse = await HttpUtil.get<HttpResponseResult<Order>>(
        `/user/order/detail?orderId=${this.orderId}`
      );

      if (orderResponse.code === 200 && orderResponse.data) {
        this.order = orderResponse.data;

        // 获取排片信息
        const scheduleResponse = await HttpUtil.get<HttpResponseResult<Schedule>>(
          `/user/schedule/detail?scheduleId=${this.order.scheduleId}`
        );

        if (scheduleResponse.code === 200 && scheduleResponse.data) {
          this.schedule = scheduleResponse.data;

          // 获取电影信息
          const movieResponse = await HttpUtil.get<HttpResponseResult<Movie>>(
            `/user/movie/detail?movieId=${this.schedule.movieId}`
          );

          if (movieResponse.code === 200 && movieResponse.data) {
            this.movie = movieResponse.data;
          }
        }
      }
    } catch (error) {
      promptAction.showToast({ message: '加载订单信息失败' });
    }
  }

  // 选择支付方式
  selectPaymentMethod(method: PaymentMethod): void {
    this.selectedMethod = method;
  }

  // 判断支付方式是否被选中
  isSelected(method: PaymentMethod): boolean {
    return this.selectedMethod === method;
  }

  // 执行支付
  async handlePay(): Promise<void> {
    if (this.isPaying) return;
    if (!this.order) {
      promptAction.showToast({ message: '订单信息不存在' });
      return;
    }

    // 余额支付先校验余额是否充足
    if (this.selectedMethod === PaymentMethod.BALANCE && this.remainingBalance < this.order.totalPrice) {
      promptAction.showToast({ message: '余额不足' });
      return;
    }

    this.isPaying = true;

    try {
      const payData: ESObject = {
        userId: this.userAccount?.id ?? 0,
        orderId: this.order.id,
        paymentMethod: this.selectedMethod,
        totalPrice: this.order.totalPrice
      };

      const response = await HttpUtil.post<HttpResponseResult<PayResult>>(
        '/user/order/pay',
        payData
      );

      if (response.code === 200) {
        promptAction.showToast({ message: '支付成功' });

        // 延迟返回上一页（订单详情页暂未创建）
        setTimeout(() => {
          this.getUIContext().getRouter().back()
        }, 800)
      } else {
        promptAction.showToast({ message: response.message || '支付失败' });
      }
    } catch (error) {
      promptAction.showToast({ message: '支付请求失败，请重试' });
    } finally {
      this.isPaying = false;
    }
  }

  build() {
    Column() {
      // ========== 顶部导航栏 ==========
      Row() {
        SymbolGlyph($r("sys.symbol.chevron_left"))
          .fontSize(24)
          .padding({ left: 5 })
          .onClick(() => {
            this.getUIContext().getRouter().back();
          });
        Text('确认订单')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center);
        Blank()
          .width(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#FFFFFF')
      .borderWidth({ bottom: 1 })
      .borderColor('#F0F0F0');

      // ========== 主要内容区域 ==========
      Scroll() {
        Column({ space: 12 }) {
          // ========== 电影信息卡片 ==========
          Column() {
            // 电影信息行（水平布局：左侧信息 + 右侧海报）
            Row() {
              // 左侧：电影信息
              Column() {
                // 电影名称
                Text(this.movie?.movieName ?? '')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                  .width('100%')
                  .margin({ bottom: 4 });

                // 时间信息
                Text(this.formatDateTime())
                  .fontSize(13)
                  .fontColor('#666666')
                  .width('100%')
                  .margin({ bottom: 2 });

                // 影院和影厅
                Row() {
                  Text(this.schedule?.cinemaName ?? '')
                    .fontSize(13)
                    .fontColor('#999999');
                  Text('·')
                    .fontSize(13)
                    .fontColor('#999999')
                    .margin({ left: 4, right: 4 });
                  Text(this.schedule?.hallName ?? '')
                    .fontSize(13)
                    .fontColor('#999999');
                }
                .width('100%')
                .margin({ bottom: 2 });

                // 座位信息
                Row() {
                  Text('座位：')
                    .fontSize(13)
                    .fontColor('#999999');
                  Text(this.order?.seatInfo ?? '')
                    .fontSize(13)
                    .fontColor('#333333')
                    .fontWeight(FontWeight.Medium);
                }
                .width('100%');
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start);

              // 右侧：电影海报
              Column() {
                Image(HttpUtil.BASE_URL + this.movie?.posterUrl)
                  .width(90)
                  .height(126)
                  .borderRadius(8)
                  .objectFit(ImageFit.Cover)
              }
              .margin({ left: 12 });
            }
            .width('100%');

            // 分割线
            Divider()
              .color('#F0F0F0')
              .height(1)
              .margin({ top: 12, bottom: 12 });

            // 底部价格信息
            Row() {
              Text('需支付：')
                .fontSize(14)
                .fontColor('#666666');
              Text(`￥${this.order?.totalPrice ?? 0}`)
                .fontSize(20)
                .fontColor('#E53935')
                .fontWeight(FontWeight.Bold);
              Text(`共${this.order?.amount ?? 0}张`)
                .fontSize(13)
                .fontColor('#999999')
                .margin({ left: 4 });
              Blank();
            }
            .width('100%');
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)' });

          // ========== 支付方式区域 ==========
          Column() {
            Text('选择支付方式')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 12 });

            // 余额显示
            Row() {
              Row() {
                Text('￥')
                  .fontSize(14)
                  .fontColor('#FF9800');
                Text(`${this.remainingBalance}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FF9800');
              }
              .padding({ left: 12, right: 16, top: 4, bottom: 4 })
              .backgroundColor('#FFF3E0')
              .borderRadius(4);

              Text('账户余额')
                .fontSize(13)
                .fontColor('#999999')
                .margin({ left: 8 });
            }
            .width('100%')
            .margin({ bottom: 12 });

            // 支付方式列表
            ForEach(this.paymentOptions, (option: PaymentOption) => {
              Row() {
                // 选择框
                Checkbox()
                  .shape(CheckBoxShape.CIRCLE)
                  .select(this.isSelected(option.key))
                  .width(20)
                  .height(20)
                  .onChange((value: boolean) => {
                    if (value) {
                      this.selectPaymentMethod(option.key);
                    }
                  });

                // 支付方式图标
                Row() {
                  Text(option.iconText)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF');
                }
                .width(44)
                .height(44)
                .backgroundColor(option.iconColor)
                .borderRadius(22)
                .justifyContent(FlexAlign.Center)
                .margin({ left: 12 });

                // 支付方式名称
                Text(option.label)
                  .fontSize(15)
                  .fontColor('#333333')
                  .margin({ left: 12 })
                  .layoutWeight(1);

                // 选中标记
                if (this.isSelected(option.key)) {
                  SymbolGlyph($r("sys.symbol.checkmark"))
                    .fontSize(18)
                    .fontColor(['#E53935']);
                }
              }
              .width('100%')
              .height(56)
              .padding({ left: 12, right: 16 })
              .backgroundColor(this.isSelected(option.key) ? '#FFF5F5' : '#FFFFFF')
              .borderRadius(8)
              .border({
                width: this.isSelected(option.key) ? 2 : 1,
                color: this.isSelected(option.key) ? '#E53935' : '#F0F0F0'
              })
              .margin({ bottom: 8 })
              .onClick(() => {
                this.selectPaymentMethod(option.key);
              });
            });
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)' });
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#F5F5F5');

      // ========== 底部支付按钮 ==========
      Column() {
        Row() {
          Column() {
            Text('需支付：')
              .fontSize(12)
              .fontColor('#999999');
            Text(`￥${this.order?.totalPrice ?? 0}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E53935');
          }
          .alignItems(HorizontalAlign.Start);

          Button(this.isPaying ? '支付中...' : '立即支付')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#E53935')
            .borderRadius(25)
            .height(50)
            .layoutWeight(1)
            .margin({ left: 24 })
            .enabled(!this.isPaying && this.order !== null)
            .onClick(() => {
              this.handlePay();
            });
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 20 })
        .backgroundColor('#FFFFFF')
        .borderWidth({ top: 1 })
        .borderColor('#F0F0F0');
      }
      .width('100%')
      .backgroundColor('#FFFFFF');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }

  // 格式化日期时间
  private formatDateTime(): string {
    if (!this.schedule) return '';
    const showTime = this.schedule.showTime;
    if (!showTime) return '';

    const date = new Date(showTime);
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');

    const endDate = new Date(date.getTime() + (this.movie?.duration ?? 0) * 60000);
    const endHours = String(endDate.getHours()).padStart(2, '0');
    const endMinutes = String(endDate.getMinutes()).padStart(2, '0');

    return `${month}月${day}日 ${hours}:${minutes}-${endHours}:${endMinutes}`;
  }
}