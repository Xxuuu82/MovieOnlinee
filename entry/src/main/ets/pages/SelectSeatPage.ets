import HttpUtil from '../../http/HttpUtil';
import promptAction from '@ohos.promptAction';
import { formatEndTime, formatMonthDate, formatStartTime } from '../common/DateUtil';
import { HallSeat, Seat, SeatRow } from '../model/HallSeat';
import { HttpResponseResult } from '../model/HttpResponseResult';
import { Order } from '../model/Order';
import { Schedule } from '../model/Schedule';
import { UserAccount } from '../model/UserAccount';

@Entry
@Component
struct SelectSeatPage {
  @State scheduleId:number=0;
  @State schedule: Schedule | null = null;
  @State hallSeat: HallSeat | null = null;
  @State selectedSeat:Seat[]=[];
  @StorageLink("userAccount")
  userAccount:UserAccount=null!

  async aboutToAppear(): Promise<void> {
    // 未登录不允许选座：replaceUrl 把当前页替换成登录页，登录返回后不会停留在空数据页面
    if (!this.userAccount) {
      this.getUIContext().getRouter().replaceUrl({
        url:"pages/loginPage"
      })
      return
    }
    const params: ESObject = this.getUIContext().getRouter().getParams();
    this.scheduleId = params?.scheduleId ?? 0;
    try {
      const httpResponse = await HttpUtil.get<HttpResponseResult<Schedule>>(
        "/user/schedule/detail?scheduleId=" + this.scheduleId
      );
      if (httpResponse.code == 200) {
        this.schedule = httpResponse.data?? null
        const hallSeat = await HttpUtil.get<HttpResponseResult<HallSeat>>(
          "/user/schedule/seat-layout?scheduleId=" + this.schedule?.id +
            "&hallId=" + this.schedule?.hallId
        );
        if (hallSeat.code == 200) {
          this.hallSeat = hallSeat.data?? null
        }
      }
    } catch (error) {
      console.error("加载场次信息异常:",error)
      promptAction.showToast({message:"加载场次信息失败，请检查网络"})
    }
  }

  // 当前座位是否被自己选中
  isSelected(seat: Seat): boolean {
    return this.selectedSeat.includes(seat)
  }

  // 移除选中的座位
  removeSeat(seat: Seat) {
    const index = this.selectedSeat.indexOf(seat);
    if (index >= 0) {
      this.selectedSeat.splice(index, 1)
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
        Text(this.schedule?.cinemaName ?? '')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 12 });
        Blank();
      }
      .width('100%')
      .padding({ top: 12, bottom: 8 })
      .justifyContent(FlexAlign.SpaceBetween);

      // ========== 影院名称 + 银幕 ==========
      Text((this.schedule?.hallName ?? '') + '银幕')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 12 });

      // ========== 座位网格（可滚动） ==========
      Scroll() {
        Column() {
          ForEach(this.hallSeat?.seatRows ?? [], (seatRow: SeatRow) => {
            Row() {
              Text(seatRow.rowName)
                .fontSize(12)
                .fontColor('#999999')
                .width(24)
                .textAlign(TextAlign.Center);

              Row() {
                ForEach(seatRow.seats, (seat: Seat) => {
                  Checkbox()
                    .shape(CheckBoxShape.ROUNDED_SQUARE)
                    .select(this.isSelected(seat) || seat.status == 1)
                    .enabled(seat.status == 0 ? true : false)
                    .width(24)
                    .height(24)
                    .onChange((value: boolean) => {
                      if (value) {
                        this.selectedSeat.push(seat);
                      } else {
                        this.removeSeat(seat);
                      }
                    });
                });
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center);
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 });
          });
        }
        .width('100%');
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .width('100%');

      // ========== 底部信息区 ==========
      Column() {
        // 电影信息
        if (this.schedule) {
          Column() {
            Text(this.schedule.movieName)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333');
            Text(`(${formatMonthDate(this.schedule.showTime.toString())})${formatStartTime(this.schedule.showTime.toString())}-${formatEndTime(this.schedule.showTime.toString(), this.schedule.movieDuration)}`)
              .fontSize(13)
              .fontColor('#999999')
              .margin({ top: 4 });
          }
          .margin({ bottom: 12 })
          .alignItems(HorizontalAlign.Center);
        }

        // ========== 已选座位标签 ==========
        if (this.selectedSeat.length > 0) {
          Row() {
            ForEach(this.selectedSeat, (seat: Seat) => {
              Row() {
                Text(seat.seatCode)
                  .fontSize(12)
                  .fontColor('#333333');
                SymbolGlyph($r("sys.symbol.xmark"))
                  .fontSize(12)
                  .fontColor(["#ffc3bfbf"])
                  .margin({ left: 4 })
                  .onClick(() => {
                    this.removeSeat(seat);
                  });
              }
              .padding({ left: 10, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#F0F0F0')
              .borderRadius(4)
              .margin({ right: 8 });
            });
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 8 });
        }

        // ========== 底部结算栏 ==========
        Row() {
          Text('总票数：' + this.selectedSeat.length + '张')
            .fontSize(14)
            .fontColor('#333333');
          Text('总金额：' + (this.selectedSeat.length * (this.schedule?.price ?? 0)) + '元')
            .fontSize(14)
            .fontColor('#333333')
            .margin({ left: 16 });
          Button('支付')
            .margin({ left: 16 })
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#E53935')
            .borderRadius(4)
            .padding({ left: 16, right: 16 })
            .enabled(this.selectedSeat.length > 0)
            .opacity(this.selectedSeat.length > 0 ? 1 : 0.5)
            .onClick(() => {
              this.createOrder();
            });
        }
        .width('100%')
        .padding({ top: 12, bottom: 16 })
        .justifyContent(FlexAlign.Center);
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .padding({ top: 12 });
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F8F8F8');
  }

  async createOrder() {
    if (this.selectedSeat.length === 0) {
      promptAction.showToast({message:"请先选择座位"})
      return
    }
    const order:ESObject = {
      scheduleId:this.scheduleId,
      seats:this.selectedSeat.map(item=>item.seatCode).join(","),
      amount:this.selectedSeat.length,
      totalPrice:this.selectedSeat.length*(this.schedule?.price ?? 0),
      userId:this.userAccount?.id,
      paymentMethod:"pending"
    }
    try {
      const result=await HttpUtil.post<HttpResponseResult<Order>>("/user/order/create",order);
      if(result.code===200&&result.data){
        // 下单成功跳转支付页
        await this.getUIContext().getRouter().pushUrl({
          url:"pages/PaymentPage",
          params:{
            orderId:result.data.id,
            totalPrice:result.data.totalPrice
          }
        })
      } else {
        promptAction.showToast({message:result.message||"下单失败，请稍后重试"})
      }
    } catch (error) {
      console.error("下单异常:",error)
      promptAction.showToast({message:"下单失败，请检查网络或后端服务"})
    }
  }
}