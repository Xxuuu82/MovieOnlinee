import { Order } from '../model/Order';
import { HttpResponseResult } from '../model/HttpResponseResult';
import HttpUtil from '../http/HttpUtil';
import { Schedule } from '../model/Schedule';
import {
  OrderStatus,
  getOrderStatusText,
  getOrderStatusColor
} from '../model/OrderStatus';

interface OrderWithCreateTime extends Order {
  createTime?: string;
}

/**
 * 更新订单状态请求参数
 */
interface UpdateStatusParams {
  orderId: number;
  status: number;
}

/**
 * 支付页面跳转参数
 */
interface PaymentPageParams {
  orderId: number;
}

/**
 * 退款请求参数
 */
interface RefundParams {
  orderId: number;
  userId: number;
}

/**
 * 取消订单请求参数
 */
interface CancelParams {
  orderId: number;
}

@Entry
@Component
struct OrderDetailPage {
  @State order: OrderWithCreateTime | null = null;
  @State orderId: number = 0;
  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  @State isUpdatingStatus: boolean = false;

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

        // ==========================================================
        // 已支付(2) + 电影已开场 → 调用 updateStatus 更新为已完成(6)
        // ==========================================================
        if (this.order.status === OrderStatus.PAID && !this.isUpdatingStatus) {
          const now = Date.now();
          const showTime = new Date(this.order.schedule?.showTime || '').getTime();
          if (now > showTime) {
            await this.updateOrderStatus(OrderStatus.COMPLETED);
          }
        }

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

  // ==========================================================
  // 调用后端更新订单状态接口
  // ==========================================================

  async updateOrderStatus(targetStatus: number): Promise<boolean> {
    if (!this.order) return false;
    if (this.isUpdatingStatus) return false;

    this.isUpdatingStatus = true;

    try {
      console.info('========== 更新订单状态 ==========');
      console.info('orderId:', this.order.id);
      console.info('targetStatus:', targetStatus);

      const reqBody: UpdateStatusParams = {
        orderId: this.order.id,
        status: targetStatus
      };

      const response = await HttpUtil.post<HttpResponseResult<null>>(
        '/user/order/updateStatus',
        reqBody
      );

      console.info('更新状态响应:', JSON.stringify(response));

      if (response.code === 200) {
        this.order.status = targetStatus;
        console.info('订单状态更新成功，当前状态:', getOrderStatusText(targetStatus));
        return true;
      } else {
        console.error('更新状态失败:', response.message);
        return false;
      }
    } catch (error) {
      console.error('更新状态异常:', error);
      return false;
    } finally {
      this.isUpdatingStatus = false;
    }
  }

  // ==========================================================
  // 状态判断方法（基于后端状态值：1待支付 2已支付 3已取消 5已退款 6已完成）
  // ==========================================================

  // 是否应该显示取票凭证（只有已支付(2)或已完成(6)才显示）
  shouldShowQRCode(): boolean {
    if (!this.order) return false;
    return this.order.status === OrderStatus.PAID ||
      this.order.status === OrderStatus.COMPLETED;
  }

  // 是否可取消（只有待支付(1)可以取消）
  isCancelable(): boolean {
    return this.order?.status === OrderStatus.PENDING;
  }

  // 是否可退款（已支付(2) + 电影未开场）
  isRefundable(): boolean {
    if (!this.order) return false;
    if (this.order.status !== OrderStatus.PAID) return false;

    const now = Date.now();
    const showTime = new Date(this.order.schedule?.showTime || '').getTime();
    return now < showTime;
  }

  // 是否已完成（已完成状态(6)，不可操作）
  isCompleted(): boolean {
    return this.order?.status === OrderStatus.COMPLETED;
  }

  // 是否已取消/已退款/已完成（不可操作）
  isFinished(): boolean {
    if (!this.order) return false;
    return this.order.status === OrderStatus.CANCELLED ||
      this.order.status === OrderStatus.REFUNDED ||
      this.order.status === OrderStatus.COMPLETED;
  }

  // 获取订单状态文本（用于底部按钮）
  getFinishedStatusText(): string {
    if (!this.order) return '';
    switch (this.order.status) {
      case OrderStatus.CANCELLED:
        return '已取消';
      case OrderStatus.REFUNDED:
        return '已退款';
      case OrderStatus.COMPLETED:
        return '已完成';
      default:
        return '';
    }
  }

  // ==========================================================
  // 业务方法
  // ==========================================================

  // 取消订单 - 使用 POST 方式（匹配后端接口）
  async cancelOrder() {
    if (this.isLoading) return;
    if (!this.order) return;

    try {
      console.info('========== 取消订单 ==========');
      console.info('orderId:', this.order.id);
      console.info('当前订单状态:', this.order.status);

      // 后端接口是 POST 方式，参数在 URL 上，body 传空对象
      // 使用 Record<string, never> 或 object 类型
      const response: HttpResponseResult<null> = await HttpUtil.post<HttpResponseResult<null>>(
        `/user/order/cancel?orderId=${this.order.id}`,
        {} as Record<string, never>  // 或者 as object
      );

      console.info('取消订单响应:', JSON.stringify(response));

      if (response.code === 200) {
        this.getUIContext().getPromptAction().showToast({ message: '订单已取消' });
        // 重新加载订单，从后端获取最新状态
        await this.loadOrderDetail();
      } else {
        this.getUIContext().getPromptAction().showToast({
          message: response.message || '取消失败'
        });
      }
    } catch (error) {
      console.error('取消异常:', error);
      this.getUIContext().getPromptAction().showToast({ message: '网络请求失败' });
    }
  }
  // 申请退款
  async refundOrder() {
    if (this.isLoading) return;
    if (!this.order) return;

    try {
      const reqBody: RefundParams = {
        orderId: this.order.id,
        userId: this.order.userId
      };

      console.info('========== 申请退款 ==========');
      console.info('请求参数:', JSON.stringify(reqBody));

      const response = await HttpUtil.post<HttpResponseResult<null>>(
        '/user/order/refund',
        reqBody
      );

      console.info('退款响应:', JSON.stringify(response));

      if (response.code === 200) {
        this.getUIContext().getPromptAction().showToast({ message: '退票成功' });
        // 重新加载订单，从后端获取最新状态
        await this.loadOrderDetail();
      } else {
        this.getUIContext().getPromptAction().showToast({ message: response.message || '退票失败' });
      }
    } catch (error) {
      console.error('退票异常:', error);
      this.getUIContext().getPromptAction().showToast({ message: '网络请求失败，请稍后重试' });
    }
  }

  // 跳转到支付页面
  goToPay() {
    if (!this.order) return;

    const params: PaymentPageParams = { orderId: this.order.id };

    this.getUIContext().getRouter().pushUrl({
      url: 'pages/PaymentPage',
      params: params
    });
  }

  goBack() {
    this.getUIContext().getRouter().back();
  }

  // ==========================================================
  // 格式化方法
  // ==========================================================

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
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return HttpUtil.BASE_URL + path;
  }

  // ==========================================================
  // 构建方法
  // ==========================================================

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

              // ==========================================================
              // 取票凭证 - 只有已支付(2)或已完成(6)才显示
              // ==========================================================
              if (this.shouldShowQRCode()) {
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
              }

              // 订单信息
              Column() {
                Row() {
                  Text('订单信息').fontSize(16).fontWeight(FontWeight.Bold)
                  Blank()
                  Text(getOrderStatusText(this.order?.status || 0))
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(getOrderStatusColor(this.order?.status || 0))
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

          // ==========================================================
          // 底部按钮（状态驱动）
          // 状态值：1待支付 2已支付 3已取消 5已退款 6已完成
          // ==========================================================
          Row() {
            if (this.isCancelable()) {
              // 待支付(1) → 取消订单 + 立即支付
              Button('取消订单')
                .type(ButtonType.Normal).width('45%').height(44)
                .backgroundColor('#F5F5F5').fontColor('#666666').borderRadius(22)
                .onClick(() => {
                  AlertDialog.show({
                    title: '确认取消',
                    message: '确定要取消此订单吗？',
                    primaryButton: {
                      value: '确定',
                      action: () => { this.cancelOrder(); }
                    },
                    secondaryButton: {
                      value: '取消',
                      action: () => { console.info('用户取消操作'); }
                    }
                  });
                })
              Button('立即支付')
                .type(ButtonType.Normal).width('45%').height(44)
                .backgroundColor('#ff35b8ff').fontColor(Color.White).borderRadius(22)
                .onClick(() => { this.goToPay(); })
            } else if (this.isRefundable()) {
              // 已支付(2) + 未开场 → 申请退款
              Button('申请退款')
                .type(ButtonType.Normal).width('90%').height(44)
                .backgroundColor('#ff35b8ff').fontColor(Color.White).borderRadius(22)
                .onClick(() => {
                  AlertDialog.show({
                    title: '确认退票',
                    message: '确定要申请退票吗？退款后座位将释放，请谨慎操作。',
                    primaryButton: {
                      value: '确定',
                      action: () => { this.refundOrder(); }
                    },
                    secondaryButton: {
                      value: '取消',
                      action: () => { console.info('用户取消退款'); }
                    }
                  });
                })
            } else if (this.isFinished()) {
              // 已取消(3)/已退款(5)/已完成(6) → 灰色不可操作按钮
              Button(this.getFinishedStatusText())
                .type(ButtonType.Normal).width('90%').height(44)
                .backgroundColor('#d9d9d9').fontColor('#999999').borderRadius(22)
                .enabled(false)
            } else {
              // 其他情况（理论上不会触发）
              Row().height(44)
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

export default OrderDetailPage;