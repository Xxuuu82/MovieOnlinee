import { formatEndTime, formatMonthDate, formatStartTime } from '../common/DateUtil';
import { HallSeat, Seat, SeatRow } from '../model/HallSeat';
import { Order } from '../model/Order';
import { Schedule } from '../model/Schedule';
import httpUtil from '../http/HttpUtil';
import { HttpResponseResult } from '../model/HttpResponseResult';
import { UserAccount } from '../model/UserAccount';


@Entry
@Component
struct SelectSeatPage{
  @State scheduleId:number=0;
  @State schedule:Schedule=null!
  @State hallSeat:HallSeat=null!
  @State selectedSeats:Seat[]=[]
  @State order:Order=null!
  @StorageLink("userAccount")
  userAccount: UserAccount | undefined = undefined

  async  aboutToAppear() {
    if(this.userAccount){
      const  params:ESObject=this.getUIContext().getRouter().getParams();
      this.scheduleId=params?.scheduleId??0
      const httpResponse = await httpUtil.get<HttpResponseResult<Schedule>>
      ("/user/schedule/detail?scheduleId="+this.scheduleId);
      if(httpResponse.code==200){
        this.schedule = httpResponse.data ;
        const hallSeat=await httpUtil.get<HttpResponseResult<HallSeat>>
        ("/user/schedule/seat-layout?scheduleId="+this.schedule.id+"&hallId="+this.schedule.hallId)
        if(hallSeat.code==200){
          this.hallSeat=hallSeat.data;
        }
      }
    }else{
      this.getUIContext().getRouter().pushUrl({
        url:"pages/loginPage"
      })
    }

  }

  build() {
    Column(){
      Row(){
        SymbolGlyph($r("sys.symbol.left_parenthesis"))
          .fontSize(20).margin({left:10})
        Text(this.schedule?.cinemaName)
        Text("")
      }.justifyContent(FlexAlign.SpaceBetween)
      Divider()
        .borderWidth(1).borderColor("#ffe3e3e3")
        .margin({top:5,bottom:10})
      Text(this.schedule?.hallName+"荧幕")
      Column(){
        ForEach(this.hallSeat?.seatRows,(seatRow:SeatRow)=>{
          Scroll(){
            Row(){
              Text(seatRow.rowName)
              ForEach(seatRow.seats,(seat:Seat)=>{
                Checkbox()
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
                  .select(seat.status==1?true:false)
                  .enabled(seat.status==0?true:false)
                  .width(24)
                  .height(24)
                  .onChange((value:boolean)=>{
                    if(value){
                      this.selectedSeats.push(seat)
                    }else{
                      const index=this.selectedSeats.indexOf(seat);
                      this.selectedSeats.splice(index,1)
                    }

                  })
              })
            }.justifyContent(FlexAlign.Center)
          }.scrollable(ScrollDirection.Horizontal)
          .width("100%")

        })
      }.width("100%")
      Text(this.schedule?.movieName)
      Row(){
        Text("("+formatMonthDate(this.schedule?.showTime.toString())+")")
        Text(formatStartTime(this.schedule?.showTime.toString()))
        Text(formatEndTime(this.schedule?.showTime.toString(),this.schedule?.movieDuration))
      }
      Flex({direction:FlexDirection.Row,wrap:FlexWrap.Wrap}){
        ForEach(this.selectedSeats,(seat:Seat)=>{
          Stack(){
            Column(){
              Text(seat.seatCode)
              Text(this.schedule?.price+"元")
            }.width(90).height(60).padding(5).margin(10)
            .backgroundColor("#ffe9e7e7")
            SymbolGlyph($r("sys.symbol.xmark"))
              .offset({x:-10,y:10})
              .onClick(()=>{
                const index=this.selectedSeats.indexOf(seat);
                this.selectedSeats.splice(index,1)
              })
          }.alignContent(Alignment.TopEnd)


        })
      }
      Row(){
        Text("总票数:"+this.selectedSeats.length+"张")
        Text("总金额:"+this.selectedSeats.length*this.schedule?.price+"元")
        Button("支付")
          .onClick(()=>{

          })
      }

    }.height("100%")
    .width("100%")
  }
  async  createOder(){
    const order:ESObject={
      scheduleId:this.scheduleId,
      seat:this.selectedSeats.map(item=>item.seatCode).join(","),
      amount:this.selectedSeats.length,
      totalPrice:this.selectedSeats.length+this.schedule.price,
      userId:this.userAccount?.id,
      paymentMethod:"pending"
    }
    const result=await httpUtil.post<HttpResponseResult<Order>>
    ("/user/order/create",order);
    if(result.code==200&&result.data){
      this.order=result.data
      this.getUIContext().getRouter().pushUrl({
        url:"支付",
        params:{
          orderId:this.order.id
        }
      })
    }
  }
}