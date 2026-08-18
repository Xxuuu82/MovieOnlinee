// entry/src/main/ets/pages/OrderDetailPage.ets

import { Order } from '../model/Order';
import { HttpResponseResult } from '../model/HttpResponseResult';
import HttpUtil from '../http/HttpUtil';
import { Schedule } from '../model/Schedule';

enum OrderStatus {
  PENDING = 1,
  PAID = 2,
  REFUNDED = 3,
  TICKETED = 4,
  EXPIRED = 5,
  COMPLETED = 6
}

function getStatusText(status: number): string {
  switch (status) {
    case OrderStatus.PENDING:
      return '待支付';
    case OrderStatus.PAID:
      return '已支付';
    case OrderStatus.REFUNDED:
      return '已退款';
    case OrderStatus.TICKETED:
      return '已出票';
    case OrderStatus.EXPIRED:
      return '已失效';
    case OrderStatus.COMPLETED:
      return '已完成';
    default:
      return '未知状态';
  }
}

interface OrderWithCreateTime extends Order {
  createTime?: string;
}

interface CancelParams {
  orderId?: number;
}

interface RefundParams {
  userId?: number;
  orderId?: number;
}

@Entry
@Component
struct OrderDetailPage {
  @State order: OrderWithCreateTime | null = null;
  @State orderId: number = 0;
  @State isLoading: boolean = true;
  @State errorMessage: string = '';

  aboutToAppear(): void {
    const params: Record<string, Object> = this.getUIContext().getRouter().getParams() as Record<string, Object>;
    this.orderId = (params?.orderId as number) ?? 0;

    if (this.orderId > 0) {
      this.loadOrderDetail();
    } else {
      this.errorMessage = '订单参数错误，请重新进入';
      this.isLoading = false;
    }
  }

  async loadOrderDetail() {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const response: HttpResponseResult<Order> = await HttpUtil.get<HttpResponseResult<Order>>(
        `/user/order/detail?orderId=${this.orderId}`
      );
      if (response.code === 200 && response.data) {
        this.order = response.data as OrderWithCreateTime;
        if (!this.order.createTime) {
          if (this.order.paymentTime) {
            this.order.createTime = new Date(this.order.paymentTime).toISOString();
          } else {
            this.order.createTime = '';
          }
        }
        console.info('订单加载成功:', this.order.orderNo);
      } else {
        this.errorMessage = response.message || '获取订单失败';
      }
    } catch (error) {
      console.error('请求异常:', error);
      this.errorMessage = '网络请求失败，请检查网络连接';
    } finally {
      this.isLoading = false;
    }
  }

  isCancelable(): boolean {
    return this.order?.status === OrderStatus.PENDING;
  }

  isRefundable(): boolean {
    return this.order?.status === OrderStatus.PAID || this.order?.status === OrderStatus.TICKETED;
  }

  async cancelOrder() {
    try {
      const reqBody: CancelParams = { orderId: this.order?.id };
      const response: HttpResponseResult<null> = await HttpUtil.post<HttpResponseResult<null>>(
        '/user/order/cancel',
        reqBody
      );
      if (response.code === 200) {
        this.getUIContext().getPromptAction().showToast({ message: '订单已取消' });
        await this.loadOrderDetail();
      } else {
        this.getUIContext().getPromptAction().showToast({ message: response.message || '取消失败' });
      }
    } catch (error) {
      console.error('取消异常:', error);
      this.getUIContext().getPromptAction().showToast({ message: '网络请求失败' });
    }
  }

  async refundOrder() {
    try {
      const reqBody: RefundParams = { userId: this.order?.userId, orderId: this.order?.id };
      const response: HttpResponseResult<null> = await HttpUtil.post<HttpResponseResult<null>>(
        '/user/order/refund',
        reqBody
      );
      if (response.code === 200) {
        this.getUIContext().getPromptAction().showToast({ message: '退票成功' });
        await this.loadOrderDetail();
      } else {
        this.getUIContext().getPromptAction().showToast({ message: response.message || '退票失败' });
      }
    } catch (error) {
      console.error('退票异常:', error);
      this.getUIContext().getPromptAction().showToast({ message: '网络请求失败' });
    }
  }

  goToPay() {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/PayPage',
      params: {
        orderId: this.order?.id,
        orderNo: this.order?.orderNo,
        totalPrice: this.order?.totalPrice,
        userId: this.order?.userId
      }
    });
  }

  goBack() {
    this.getUIContext().getRouter().back();
  }

  formatDate(showTime: string): string {
    if (!showTime) return '--';
    try {
      const date: Date = new Date(showTime);
      return (date.getMonth() + 1) + '月' + date.getDate() + '日';
    } catch {
      return '--';
    }
  }

  formatTimeRange(showTime: string, duration: number): string {
    if (!showTime || !duration) return '--';
    try {
      const start: Date = new Date(showTime);
      const end: Date = new Date(start.getTime() + duration * 60000);
      const pad = (n: number) => String(n).padStart(2, '0');
      return pad(start.getHours()) + ':' + pad(start.getMinutes()) + '-' +
        pad(end.getHours()) + ':' + pad(end.getMinutes());
    } catch {
      return '--';
    }
  }

  formatSeats(seatInfo: string): string {
    if (!seatInfo) return '--';
    return seatInfo.split(',').map((s: string) => s.trim()).join('、');
  }

  formatDateTime(timeStr: string): string {
    if (!timeStr) return '--';
    try {
      const date: Date = new Date(timeStr);
      return date.getFullYear() + '年' + (date.getMonth() + 1) + '月' + date.getDate() + '日 ' +
        String(date.getHours()).padStart(2, '0') + ':' + String(date.getMinutes()).padStart(2, '0');
    } catch {
      return timeStr;
    }
  }

  getFullImageUrl(path: string): string {
    if (!path) return '';
    return HttpUtil.BASE_URL + path;
  }

  build() {
    Column() {
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color('#1698CE')
          Text('加载中...').margin({ top: 10 }).fontSize(14).fontColor('#999999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage) {
        Column() {
          Text(this.errorMessage).fontSize(16).fontColor('#ff35b8ff')
          Button('重试').margin({ top: 20 }).onClick(() => { this.loadOrderDetail() })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.order) {
        Column() {
          // 标题栏
          Row() {
            SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(26).onClick(() => { this.goBack() })
            Text('订单详情').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
            Blank().width(26)
          }
          .width('100%').height(44).padding({ left: 12, right: 16 }).backgroundColor('#FFFFFF')

          Scroll() {
            Column() {
              // 影院名称
              Text(this.order?.schedule?.cinemaName || '影院名称')
                .fontSize(18).fontWeight(FontWeight.Medium).width('100%').margin({ top: 16 })

              // 电影信息
              Row() {
                Column() {
                  Text(this.order?.schedule?.movieName || '电影名称').fontSize(20).fontWeight(FontWeight.Bold).width('100%')
                  Text((this.order?.schedule?.hallType || '') + '  ' + this.order?.amount + '张')
                    .fontSize(14).fontColor('#666666').width('100%').margin({ top: 10 })
                  Text(this.formatDate(this.order?.schedule?.showTime || '') + ' ' + (this.order?.hallName || ''))
                    .fontSize(14).fontColor('#666666').width('100%').margin({ top: 8 })
                  Text(this.formatTimeRange(this.order?.schedule?.showTime || '', this.order?.schedule?.movieDuration || 0))
                    .fontSize(14).fontColor('#666666').width('100%').margin({ top: 8 })
                  Text(this.formatSeats(this.order?.seatInfo || ''))
                    .fontSize(14).fontColor('#ff35b8ff').width('100%').margin({ top: 8 })
                }
                .alignItems(HorizontalAlign.Start).layoutWeight(1)

                Image(this.getFullImageUrl(this.order?.schedule?.moviePoster || ''))
                  .width(100).height(140).borderRadius(8).objectFit(ImageFit.Cover).backgroundColor('#F5F5F5')
              }
              .width('100%').padding(16).margin({ top: 12 }).backgroundColor('#FFFFFF').borderRadius(12).alignItems(VerticalAlign.Top)

              // 取票凭证
              Column() {
                Text('取票凭证').fontSize(16).fontWeight(FontWeight.Medium).width('100%').margin({ bottom: 12 })
                Column() {
                  if (this.order?.orderNo) {
                    QRCode(this.order.orderNo).width(160).height(160).color(Color.Black).backgroundColor(Color.White)
                  } else {
                    Text('暂无二维码').fontSize(14).fontColor('#999999')
                  }
                }
                .width('100%').height(200).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
              }
              .width('100%').padding(16).margin({ top: 12 }).backgroundColor('#FFFFFF').borderRadius(12)

              // 订单信息
              Column() {
                Row() {
                  Text('订单信息').fontSize(16).fontWeight(FontWeight.Bold)
                  Blank()
                  Text(getStatusText(this.order?.status || 0)).fontSize(16).fontWeight(FontWeight.Medium).fontColor('#333333')
                }
                .width('100%').margin({ bottom: 14 })

                Row() {
                  Text('订单编号').fontSize(14).fontColor('#666666')
                  Blank()
                  Text(this.order?.orderNo || '--').fontSize(14).fontColor('#333333').maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis }).width('50%').textAlign(TextAlign.End)
                }
                .width('100%').margin({ bottom: 8 })

                Row() {
                  Text('下单时间').fontSize(14).fontColor('#666666')
                  Blank()
                  Text(this.formatDateTime(this.order?.createTime || '')).fontSize(14).fontColor('#333333').textAlign(TextAlign.End)
                }
                .width('100%')
              }
              .width('100%').padding(16).margin({ top: 12 }).backgroundColor('#FFFFFF').borderRadius(12)

              // 观影须知
              Column() {
                Text('观影须知').fontSize(16).fontWeight(FontWeight.Medium).width('100%').margin({ bottom: 8 })
                Text('1. 请提前到达影院现场，通过影院自助取票机完成取票').fontSize(13).fontColor('#666666').width('100%').margin({ top: 2 })
                Text('2. 电影开场后请将手机调至静音或震动模式').fontSize(13).fontColor('#666666').width('100%').margin({ top: 4 })
                Text('3. 影厅内禁止吸烟，请勿携带异味食品').fontSize(13).fontColor('#666666').width('100%').margin({ top: 4 })
              }
              .width('100%').padding(16).margin({ top: 12 }).backgroundColor('#FFFFFF').borderRadius(12)
            }
            .padding({ left: 16, right: 16, bottom: 20 }).width('100%')
          }
          .layoutWeight(1).scrollBar(BarState.Off)

          // 底部按钮
          Row() {
            if (this.isCancelable()) {
              Button('取消订单').type(ButtonType.Normal).width('45%').height(44)
                .backgroundColor('#F5F5F5').fontColor('#666666').borderRadius(22)
                .onClick(() => {
                  const dialogParam: AlertDialogParamWithButtons = {
                    title: '确认取消',
                    message: '确定要取消此订单吗？',
                    primaryButton: { value: '确定', action: () => { this.cancelOrder() } },
                    secondaryButton: { value: '取消', action: () => {} }
                  };
                  AlertDialog.show(dialogParam);
                })
              Button('立即支付').type(ButtonType.Normal).width('45%').height(44)
                .backgroundColor('#ff35b8ff').fontColor(Color.White).borderRadius(22)
                .onClick(() => { this.goToPay() })
            } else if (this.isRefundable()) {
              Button('申请退款').type(ButtonType.Normal).width('90%').height(44)
                .backgroundColor('#ff35b8ff').fontColor(Color.White).borderRadius(22)
                .onClick(() => {
                  const dialogParam: AlertDialogParamWithButtons = {
                    title: '确认退票',
                    message: '确定要申请退票吗？',
                    primaryButton: { value: '确定', action: () => { this.refundOrder() } },
                    secondaryButton: { value: '取消', action: () => {} }
                  };
                  AlertDialog.show(dialogParam);
                })
            } else {
              Button('返回首页').type(ButtonType.Normal).width('90%').height(44)
                .backgroundColor('#ff35b8ff').fontColor(Color.White).borderRadius(22)
                .onClick(() => { this.getUIContext().getRouter().replaceUrl({ url: 'pages/IndexPage' }) })
            }
          }
          .width('100%').height(80).justifyContent(FlexAlign.SpaceEvenly)
          .backgroundColor('#FFFFFF').padding({ bottom: 10 })
        }
        .width('100%').height('100%')
      } else {
        Text('暂无数据')
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }
}