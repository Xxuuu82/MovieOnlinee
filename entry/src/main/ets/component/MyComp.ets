import HttpUtil from "../http/HttpUtil"

import { UserAccount } from "../model/UserAccount"

@CustomDialog
struct CustomDialogExample {
  controller?: CustomDialogController;

  build() {
    Column() {
      // 请将$r('app.string.i_am_content')替换为实际资源文件，在本示例中该资源文件的value值为"我是内容"
      Text("弹框")
        .fontSize(20)
    }.height(60).justifyContent(FlexAlign.Center)
  }
}


@Component
export struct MyComp{

  @StorageLink("userAccount")
  userAccount:UserAccount| undefined = undefined
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomDialogExample(),
  })
  build() {
    Column({space:20}){
      Column(){
        if (this.userAccount){
          Row(){
            Image(HttpUtil.BASE_URL+this.userAccount.avatarUrl)
              .width(80)
              .borderRadius(40)
            Column(){
              Text(this.userAccount?.nickname)
              Text(this.userAccount?.email)
              Text(this.userAccount.phone)
            }
          }
        }else {
          Button("登录")
            .type(ButtonType.Normal)
            .borderRadius(5)
            .onClick(()=>{
              this.getUIContext().getRouter().pushUrl({
                url:"pages/LoginPage"
              })
            })
        }
      }.height(100)

      Row(){
        Column(){
          SymbolGlyph($r("sys.symbol.star"))
          Text("收藏")
        }
        Column(){
          SymbolGlyph($r("sys.symbol.star"))
          Text("看过")
        }
        Column(){
          SymbolGlyph($r("sys.symbol.edit_badge_star"))
          Text("评论")
        }
      }.width("80%")
      .height(80)
      .borderWidth(2)
      .borderColor("#ffd2d2d2")
      .borderRadius(10)
      .justifyContent(FlexAlign.SpaceEvenly)

      if (this.userAccount){
        Row(){
          Column(){
            SymbolGlyph($r("sys.symbol.star"))

          }
          Column(){
            SymbolGlyph($r("sys.symbol.star"))
            Text("尊享会员")
          }
          Column(){
            Button("续费").onClick((event:ClickEvent)=>{

            })
          }
        }.width("80%")
        .height(70)
        .borderWidth(2)
        .borderColor("#ffd2d2d2")
        .borderRadius(10)
        .padding({left:15,right:15})
        .justifyContent(FlexAlign.SpaceBetween)
      }
      List(){
        ListItem(){
          Row(){
            SymbolGlyph($r("sys.symbol.order_play"))
            Text("我的订单").padding({left:5})
            Blank()
            SymbolGlyph($r("sys.symbol.right_key"))
          }.width("95%")
          .height(60)
          .justifyContent(FlexAlign.SpaceBetween)
          .onClick(()=>{
            if (this.userAccount) {
              this.getUIContext().getRouter().pushUrl({
                url: "pages/OrderListPage"
              });
            } else {
              this.getUIContext().getPromptAction().showToast({
                message: "请先登录",
                bottom: "50%"
              });
            }
          })
        }
        ListItem(){
          Row(){
            SymbolGlyph($r("sys.symbol.order_play"))
            Text("优惠券").padding({left:5})
            Blank()
            SymbolGlyph($r("sys.symbol.right_key"))
          }.width("95%")
          .height(60)
          .justifyContent(FlexAlign.SpaceBetween)
        }
        ListItem(){
          Row(){
            SymbolGlyph($r("sys.symbol.order_play"))
            Text("充值中心").padding({left:5})
            Blank()
            SymbolGlyph($r("sys.symbol.right_key"))
          }.width("95%")
          .height(60)
          .justifyContent(FlexAlign.SpaceBetween)
          .onClick(()=>{
            if(this.userAccount){
              this.dialogController.open()
            }else{
              this.getUIContext().getPromptAction().showToast({
                message:"请先登录",
                bottom:"50%"
              })
            }

          })
        }
        ListItem(){
          Row(){
            SymbolGlyph($r("sys.symbol.order_play"))
            Text("个人中心").padding({left:5})
            Blank()
            SymbolGlyph($r("sys.symbol.right_key"))
          }.width("95%")
          .height(60)
          .justifyContent(FlexAlign.SpaceBetween)
        }

      }.divider({strokeWidth:1,color:"#ffe2dcdc",startMargin:10})

      if(this.userAccount){
        Button("退出登录")
          .type(ButtonType.Normal)
          .borderRadius(5)
          .onClick(() => {
            // 清除用户信息
            AppStorage.setOrCreate("userAccount", undefined)
            this.userAccount = undefined

            this.getUIContext().getPromptAction().showToast({
              message: "已退出登录",
              bottom: "50%"
            })
          })
      }

    }.width("100%")
    .height("100%")

  }

}
