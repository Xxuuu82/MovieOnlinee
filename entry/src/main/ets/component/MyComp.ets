import HttpUtil from "../../http/HttpUtil";
import { UserAccount } from "../model/UserAccount";

@CustomDialog
struct CustomDialogExample {
  controller?: CustomDialogController;

  build() {
    Column() {
      Text("弹框")
        .fontSize(20)
    }
    .height(60)
    .justifyContent(FlexAlign.Center);
  }
}

@Entry
@Component
export struct MyComp {
  @StorageLink("userAccount")
  userAccount: UserAccount | undefined = undefined;
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomDialogExample(),  // 使用正确的组件名
  });

  build() {
    Column({ space: 20 }) {
      // ========== 用户信息/登录按钮 ==========
      Column() {
        if (this.userAccount) {
          Row() {
            Image(HttpUtil.BASE_URL + this.userAccount.avatarUrl)
              .width(80)
              .borderRadius(40);
            Column() {
              Text(this.userAccount.nickname);
              Text(this.userAccount.email);
              Text(this.userAccount.phone);
            }
          };
        } else {
          Button("登录")
            .type(ButtonType.Normal)
            .borderRadius(10)
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({
                url: "pages/loginPage"
              });
            });
        }
      }
      .height(100);

      // ========== 收藏/看过/评分 ==========
      Row() {
        Column() {
          SymbolGlyph($r("sys.symbol.star"));
          Text("收藏");
        }
        Column() {
          SymbolGlyph($r("sys.symbol.star"));
          Text("看过");
        }
        Column() {
          SymbolGlyph($r("sys.symbol.star"));
          Text("评分");
        }
      }
      .width("80%")
      .height(70)
      .borderWidth(2)
      .borderColor("#ff9d9a9a")
      .borderRadius(10)
      .justifyContent(FlexAlign.SpaceBetween);

      // ========== 尊享会员 ==========
      if (this.userAccount) {
        Row() {
          Column() {
            SymbolGlyph($r("sys.symbol.star"));
          }
          Column() {
            Text("尊享会员");
          }
          Column() {
            Button("续费")
              .onClick((event: ClickEvent) => {
                // 续费逻辑
              });
          }
        }
        .width("80%")
        .height(70)
        .borderWidth(2)
        .borderColor("#ff9d9a9a")
        .borderRadius(10)
        .padding({ left: 15, right: 15 })
        .justifyContent(FlexAlign.SpaceBetween);
      }

      // ========== 列表菜单 ==========
      List() {
        ListItem() {
          Row() {
            SymbolGlyph($r("sys.symbol.order_play"));
            Text("我的订单");
            SymbolGlyph($r("sys.symbol.right_key"));
          }
          .width("95%")
          .height(60)
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 35, right: 35 });
        }

        ListItem() {
          Row() {
            SymbolGlyph($r("sys.symbol.order_play"));
            Text("优惠券");
            SymbolGlyph($r("sys.symbol.right_key"));
          }
          .width("95%")
          .height(60)
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 35, right: 35 });
        }

        ListItem() {
          Row() {
            SymbolGlyph($r("sys.symbol.order_play"));
            Text("充值中心");
            SymbolGlyph($r("sys.symbol.right_key"));
          }
          .width("95%")
          .height(60)
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 35, right: 35 });
        }

        ListItem() {
          Row() {
            SymbolGlyph($r("sys.symbol.order_play"));
            Text("设置");
            SymbolGlyph($r("sys.symbol.right_key"));
          }
          .width("95%")
          .height(60)
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 35, right: 35 });
        }

        ListItem() {
          Row() {
            SymbolGlyph($r("sys.symbol.order_play"));
            Text("帮助中心");
            SymbolGlyph($r("sys.symbol.right_key"));
          }
          .width("95%")
          .height(60)
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 35, right: 35 });
        }
      }
      .divider({ strokeWidth: 2, color: "#ff242222", startMargin: 10 });

      // ========== 退出登录按钮 ==========
      if (this.userAccount) {
        Button("退出登录")
          .type(ButtonType.Normal)
          .borderRadius(10)
          .onClick(() => {
            AppStorage.setOrCreate("userAccount", undefined);
            this.userAccount = undefined;
            this.getUIContext().getPromptAction().showToast({
              message: "已退出登录",
              bottom: "50%"
            });
          });
      }
    }
    .width("100%")
    .height("100%");
  }
}