// pages/OrderListPage.ets

import HttpUtil from '../http/HttpUtil';
import { HttpResponseResult } from '../model/HttpResponseResult';
import { UserAccount } from '../model/UserAccount';
import { Order } from '../model/Order';
import {
  OrderStatus,
  getOrderStatusText,
  getOrderStatusColor
} from '../model/OrderStatus';
import {
  formatMonthDate,
  formatStartTime
} from '../common/DateUtil';

/**
 * 状态标签接口
 */
interface StatusTab {
  label: string;
  value: OrderStatus;
}

/**
 * PaymentPage 跳转参数
 */
interface PaymentPageParams {
  orderId: number;
}

/**
 * OrderDetailPage 跳转参数
 */
interface OrderDetailPageParams {
  orderId: number;
}

@Entry
@Component
struct OrderListPage {

  // =========================================================
  // 状态数据
  // =========================================================

  @State orders: Order[] = [];
  @State filteredOrders: Order[] = [];
  @State currentStatus: OrderStatus = OrderStatus.ALL;
  @State isLoading: boolean = false;
  @State isCancelling: boolean = false;
  @State cancellingOrderId: number = 0;

  @StorageLink("userAccount")
  userAccount: UserAccount | undefined = undefined;

  // =========================================================
  // 状态筛选标签
  // =========================================================
  //
  // 状态码说明（与后端一致）：
  // 1 = 待支付
  // 2 = 已支付
  // 3 = 已取消
  // 5 = 已退款
  // 6 = 已完成
  // =========================================================

  private statusTabs: StatusTab[] = [
    { label: '全部', value: OrderStatus.ALL },
    { label: '待支付', value: OrderStatus.PENDING },
    { label: '已支付', value: OrderStatus.PAID },
    { label: '已取消', value: OrderStatus.CANCELLED },
    { label: '已退款', value: OrderStatus.REFUNDED },
    { label: '已完成', value: OrderStatus.COMPLETED }
  ];

  // =========================================================
  // 页面生命周期
  // =========================================================

  async aboutToAppear(): Promise<void> {
    console.info('========== OrderListPage aboutToAppear ==========');

    if (!this.userAccount) {
      this.getUIContext()
        .getPromptAction()
        .showToast({
          message: '请先登录',
          bottom: '40%'
        });

      setTimeout(() => {
        this.getUIContext().getRouter().back();
      }, 500);

      return;
    }

    await this.loadOrders();
  }

  /**
   * 页面重新显示时刷新订单列表
   */
  async onPageShow(): Promise<void> {
    console.info('========== OrderListPage onPageShow ==========');

    if (!this.userAccount) {
      return;
    }

    await this.loadOrders();
  }

  // =========================================================
  // 获取订单列表
  // =========================================================

  async loadOrders(): Promise<void> {
    const userId = this.userAccount?.id ?? 0;

    if (userId <= 0) {
      console.error('获取订单列表失败：userId 无效');
      return;
    }

    if (this.isLoading) {
      return;
    }

    this.isLoading = true;

    try {
      console.info('========== 获取订单列表 ==========');
      console.info('userId:', userId);

      const result = await HttpUtil.get<HttpResponseResult<Order[]>>(
        `/user/order/list?userId=${userId}`
      );

      console.info('订单列表响应:', JSON.stringify(result));

      if (result.code === 200 && result.data) {
        this.orders = result.data;
        this.filterOrders();
        console.info('订单总数量:', this.orders.length);
        this.printOrderStatus();
      } else {
        this.orders = [];
        this.filteredOrders = [];
        this.getUIContext()
          .getPromptAction()
          .showToast({
            message: result.message || '加载订单失败',
            bottom: '40%'
          });
      }
    } catch (error) {
      console.error('加载订单异常:', error);
      this.getUIContext()
        .getPromptAction()
        .showToast({
          message: '网络异常，请稍后重试',
          bottom: '40%'
        });
    } finally {
      this.isLoading = false;
    }
  }

  // =========================================================
  // 输出订单状态调试信息
  // =========================================================

  private printOrderStatus(): void {
    console.info('========== 当前订单状态 ==========');
    this.orders.forEach((order: Order) => {
      console.info(
        `订单 ${order.id} / ${order.orderNo} / status=${order.status} / ${getOrderStatusText(order.status)}`
      );
    });
  }

  // =========================================================
  // 根据当前状态过滤订单
  // =========================================================

  filterOrders(): void {
    if (this.currentStatus === OrderStatus.ALL) {
      this.filteredOrders = this.orders;
      return;
    }

    this.filteredOrders = this.orders.filter(
      (order: Order) => order.status === this.currentStatus
    );
  }

  // =========================================================
  // 日期时间处理
  // =========================================================

  getShowTimeString(showTime: string | Date | undefined): string {
    if (!showTime) return '';
    if (typeof showTime === 'string') {
      return showTime;
    }
    return showTime.toISOString();
  }

  getFormattedShowTime(order: Order): string {
    if (!order.schedule?.showTime) return '';
    const showTimeStr = this.getShowTimeString(order.schedule.showTime);
    if (!showTimeStr) return '';
    return formatMonthDate(showTimeStr) + ' ' + formatStartTime(showTimeStr);
  }

  // =========================================================
  // 获取电影海报
  // =========================================================

  getMoviePoster(order: Order): string {
    const poster = order.schedule?.moviePoster || '';
    if (!poster) return '';
    if (poster.startsWith('http://') || poster.startsWith('https://')) {
      return poster;
    }
    return HttpUtil.BASE_URL + poster;
  }

  // =========================================================
  // 跳转订单详情
  // =========================================================

  goToOrderDetail(orderId: number): void {
    console.info('========== 跳转订单详情 ==========');
    console.info('orderId:', orderId);

    const params: OrderDetailPageParams = { orderId: orderId };

    this.getUIContext().getRouter().pushUrl({
      url: 'pages/OrderDetailPage',
      params: params
    });
  }

  // =========================================================
  // 跳转支付页面
  // =========================================================

  payOrder(order: Order): void {
    console.info('========== 跳转支付页面 ==========');
    console.info('orderId:', order.id);
    console.info('orderNo:', order.orderNo);
    console.info('totalPrice:', order.totalPrice);

    const params: PaymentPageParams = { orderId: order.id };

    this.getUIContext().getRouter().pushUrl({
      url: 'pages/PaymentPage',
      params: params
    });
  }

  // =========================================================
  // 取消订单
  // =========================================================

  async cancelOrder(orderId: number): Promise<void> {
    if (this.isCancelling) return;

    if (orderId <= 0) {
      this.getUIContext()
        .getPromptAction()
        .showToast({
          message: '订单 ID 无效'
        });
      return;
    }

    const targetOrder = this.orders.find(
      (order: Order) => order.id === orderId
    );

    if (!targetOrder || targetOrder.status !== OrderStatus.PENDING) {
      this.getUIContext()
        .getPromptAction()
        .showToast({
          message: '当前订单不能取消'
        });
      return;
    }

    this.isCancelling = true;
    this.cancellingOrderId = orderId;

    try {
      console.info('========== 取消订单 ==========');
      console.info('orderId:', orderId);

      const result = await HttpUtil.post<HttpResponseResult<Object>>(
        `/user/order/cancel?orderId=${orderId}`
      );

      console.info('取消订单响应:', JSON.stringify(result));

      if (result.code === 200) {
        this.getUIContext()
          .getPromptAction()
          .showToast({
            message: '订单已取消',
            bottom: '40%'
          });

        await this.loadOrders();
      } else {
        this.getUIContext()
          .getPromptAction()
          .showToast({
            message: result.message || '取消订单失败',
            bottom: '40%'
          });
      }
    } catch (error) {
      console.error('取消订单异常:', error);
      this.getUIContext()
        .getPromptAction()
        .showToast({
          message: '取消订单失败，请稍后重试',
          bottom: '40%'
        });
    } finally {
      this.isCancelling = false;
      this.cancellingOrderId = 0;
    }
  }

  // =========================================================
  // 显示取消确认对话框
  // =========================================================

  showCancelDialog(orderId: number): void {
    AlertDialog.show({
      title: '确认取消',
      message: '确定要取消此订单吗？',
      primaryButton: {
        value: '确定',
        action: () => {
          this.cancelOrder(orderId);
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
          console.info('用户取消操作');
        }
      }
    });
  }

  // =========================================================
  // 状态标签
  // =========================================================

  @Builder
  buildStatusTab(tab: StatusTab) {
    Text(tab.label)
      .fontSize(14)
      .fontWeight(
        this.currentStatus === tab.value
          ? FontWeight.Medium
          : FontWeight.Normal
      )
      .fontColor(
        this.currentStatus === tab.value
          ? '#1890ff'
          : '#666666'
      )
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .border({
        width: { bottom: this.currentStatus === tab.value ? 2 : 0 },
        color: '#1890ff'
      })
      .onClick(() => {
        this.currentStatus = tab.value;
        this.filterOrders();
      });
  }

  // =========================================================
  // 订单卡片
  // =========================================================

  @Builder
  buildOrderItem(order: Order) {
    Column() {
      // =====================================================
      // 订单头部
      // =====================================================

      Row() {
        Text(order.schedule?.cinemaName || '未知影院')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1);

        Text(getOrderStatusText(order.status))
          .fontSize(14)
          .fontColor(getOrderStatusColor(order.status));
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 8 });

      Divider()
        .height(1)
        .color('#F0F0F0')
        .margin({ left: 12, right: 12 });

      // =====================================================
      // 订单内容
      // =====================================================

      Row() {
        if (this.getMoviePoster(order)) {
          Image(this.getMoviePoster(order))
            .width(80)
            .height(110)
            .borderRadius(6)
            .objectFit(ImageFit.Cover)
            .margin({ right: 12 })
            .alt($r('app.media.startIcon'))
            .onError(() => {
              console.error(`海报加载失败: ${this.getMoviePoster(order)}`);
            });
        } else {
          Column() {
            Text('暂无海报')
              .fontSize(12)
              .fontColor('#999999');
          }
          .width(80)
          .height(110)
          .backgroundColor('#F5F5F5')
          .borderRadius(6)
          .justifyContent(FlexAlign.Center)
          .margin({ right: 12 });
        }

        Column({ space: 6 }) {
          Text(order.schedule?.movieName || '未知影片')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          Row() {
            Text('影厅：')
              .fontSize(13)
              .fontColor('#666666');
            Text(order.hallName || order.schedule?.hallName || '未知影厅')
              .fontSize(13)
              .fontColor('#333333');
          }
          .width('100%');

          Row() {
            Text('观影时间：')
              .fontSize(13)
              .fontColor('#666666');
            Text(this.getFormattedShowTime(order))
              .fontSize(13)
              .fontColor('#333333');
          }
          .width('100%');

          Row() {
            Text('座位：')
              .fontSize(13)
              .fontColor('#666666');
            Text(order.seatInfo || '')
              .fontSize(13)
              .fontColor('#333333')
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
            Text(`(${order.amount || 0}张)`)
              .fontSize(13)
              .fontColor('#666666');
          }
          .width('100%');

          Row() {
            Text('总价格：')
              .fontSize(13)
              .fontColor('#666666');
            Text(`￥${order.totalPrice?.toFixed(2) || '0.00'}`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E53935');
          }
          .width('100%');

          Row() {
            Text('订单号：')
              .fontSize(12)
              .fontColor('#999999');
            Text(order.orderNo || '')
              .fontSize(12)
              .fontColor('#999999')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1);
          }
          .width('100%');
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 });

      // =====================================================
      // 底部留白（原操作按钮区域已删除）
      // =====================================================
      Row()
        .width('100%')
        .height(12);
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .onClick(() => {
      // 点击卡片跳转订单详情
      this.goToOrderDetail(order.id);
    });
  }

  // =========================================================
  // 页面 UI
  // =========================================================

  build() {
    Column() {
      // =====================================================
      // 顶部导航
      // =====================================================

      Row() {
        SymbolGlyph($r("sys.symbol.chevron_left"))
          .fontSize(24)
          .fontColor([Color.Black])
          .padding({ left: 5 })
          .onClick(() => {
            console.info('返回"我的"页面');
            this.getUIContext().getRouter().replaceUrl({
              url: 'pages/Index',
              params: {
                targetIndex: 3  // "我的" Tab 的索引
              }
            });
          });

        Text('我的订单')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center);

        Row().width(24);
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF');

      Divider().borderWidth(1);

      // =====================================================
      // 状态筛选栏
      // =====================================================

      Scroll() {
        Row() {
          ForEach(this.statusTabs, (tab: StatusTab) => {
            this.buildStatusTab(tab);
          });
        }
        .padding({ left: 8, right: 8 })
        .height(44);
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .backgroundColor('#FFFFFF');

      // =====================================================
      // 订单列表
      // =====================================================

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#1890FF')
            .margin({ top: 60 });
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 });
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else if (this.filteredOrders.length === 0) {
        Column() {
          SymbolGlyph($r("sys.symbol.list_bullet"))
            .fontSize(60)
            .fontColor([Color.Gray])
            .margin({ top: 60 });
          Text('暂无订单')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 16 });
          Text(
            this.currentStatus === OrderStatus.ALL
              ? '快去购买电影票吧'
              : '该状态暂无订单'
          )
            .fontSize(14)
            .fontColor('#BFBFBF')
            .margin({ top: 8 });
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else {
        List() {
          ForEach(this.filteredOrders, (order: Order) => {
            ListItem() {
              this.buildOrderItem(order);
            }
            .margin({ left: 16, right: 16, top: 12 });
          });
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ bottom: 12 });
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F5F5F5');
  }
}

export default OrderListPage;