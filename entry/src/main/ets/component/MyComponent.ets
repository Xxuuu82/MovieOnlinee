import { HttpUtil } from "../http/HttpUtil"
import { UserAccount } from "../model/UserAccount"

@Entry
@Component
export struct MyComponent {

  // ==========================================================
  // 当前登录用户
  //
  // 关键：
  // 使用 StorageLink 监听 AppStorage 中的 userAccount
  //
  // LoginPage 登录成功：
  // AppStorage.setOrCreate('userAccount', account)
  //
  // 这里会自动更新
  // ==========================================================

  @StorageLink('userAccount')
  userAccount: UserAccount | null = null


  // ==========================================================
  // 跳转登录页面
  // ==========================================================

  goToLogin(): void {
    this.getUIContext()
      .getRouter()
      .pushUrl({
        url: 'pages/LoginPage'
      })
  }


  // ==========================================================
  // 点击收藏
  // ==========================================================

  goToFavorite(): void {

    // 未登录
    if (!this.userAccount) {
      this.goToLogin()
      return
    }

    // 已登录
    this.getUIContext()
      .getRouter()
      .pushUrl({
        url: 'pages/FavoriteListPage'
      })
  }


  // ==========================================================
  // 退出登录
  // ==========================================================

  logout(): void {

    // 删除当前用户
    AppStorage.delete('userAccount')

    // 删除登录状态
    AppStorage.delete('isLogin')

    console.info('用户已退出登录')
  }


  // ==========================================================
  // 获取头像文字
  // ==========================================================

  getAvatarText(): string {

    if (this.userAccount?.nickname) {
      return this.userAccount.nickname.substring(0, 1)
    }

    if (this.userAccount?.username) {
      return this.userAccount.username.substring(0, 1)
    }

    return '我'
  }


  build() {

    Column() {

      Scroll() {

        Column() {

          // ==================================================
          // 用户信息区域
          // ==================================================

          if (this.userAccount) {

            // ================================
            // 已登录
            // ================================

            Row() {

              // 用户头像
              if (this.userAccount.avatarUrl) {

                Image(
                  HttpUtil.BASE_URL +
                    this.userAccount.avatarUrl
                )
                  .width(80)
                  .height(80)
                  .borderRadius(40)
                  .objectFit(ImageFit.Cover)

              } else {

                // 没有头像时显示默认头像
                Column() {

                  Text(this.getAvatarText())
                    .fontSize(30)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#666666')

                }
                .width(80)
                .height(80)
                .borderRadius(40)
                .backgroundColor('#EEEEEE')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
              }


              // 用户基本信息
              Column() {

                Text(
                  this.userAccount.nickname ||
                    this.userAccount.username ||
                    '用户'
                )
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#222222')

                Text(
                  this.userAccount.email ||
                    '未绑定邮箱'
                )
                  .fontSize(13)
                  .fontColor('#888888')
                  .margin({ top: 6 })

                Text(
                  this.userAccount.phone ||
                    '未绑定手机号'
                )
                  .fontSize(13)
                  .fontColor('#888888')
                  .margin({ top: 4 })

              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({ left: 14 })

            }
            .width('100%')
            .padding({
              left: 24,
              right: 24,
              top: 24,
              bottom: 20
            })

          } else {

            // ==================================================
            // 未登录
            // ==================================================

            Row() {

              Column() {

                SymbolGlyph(
                  $r('sys.symbol.person_crop_circle_fill')
                )
                  .fontSize(50)
                  .fontColor(['#AAAAAA'])

              }
              .width(70)
              .height(70)
              .justifyContent(FlexAlign.Center)


              Column() {

                Text('未登录')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')

                Text('登录后查看个人信息')
                  .fontSize(13)
                  .fontColor('#999999')
                  .margin({ top: 6 })

              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({ left: 14 })


              Button('登录')
                .width(60)
                .height(32)
                .fontSize(13)
                .fontColor('#FFFFFF')
                .backgroundColor('#1698CE')
                .borderRadius(16)
                .onClick(() => {
                  this.goToLogin()
                })

            }
            .width('100%')
            .padding({
              left: 24,
              right: 24,
              top: 24,
              bottom: 20
            })
          }


          // ==================================================
          // 收藏 / 看过 / 评分
          // ==================================================

          Row() {

            // 收藏
            Column() {

              SymbolGlyph(
                $r('sys.symbol.heart')
              )
                .fontSize(25)
                .fontColor(['#333333'])

              Text('收藏')
                .fontSize(14)
                .fontColor('#53B7AE')
                .fontWeight(FontWeight.Bold)
                .margin({ top: 6 })

            }
            .layoutWeight(1)
            .onClick(() => {
              this.goToFavorite()
            })


            // 看过
            Column() {

              SymbolGlyph(
                $r('sys.symbol.template')
              )
                .fontSize(25)
                .fontColor(['#333333'])

              Text('看过')
                .fontSize(14)
                .fontColor('#53B7AE')
                .fontWeight(FontWeight.Bold)
                .margin({ top: 6 })

            }
            .layoutWeight(1)


            // 评分
            Column() {

              SymbolGlyph(
                $r('sys.symbol.star')
              )
                .fontSize(25)
                .backgroundColor('#d4e7fa')

              Text('评分')
                .fontSize(14)
                .fontColor('#53B7AE')
                .fontWeight(FontWeight.Bold)
                .margin({ top: 6 })

            }
            .layoutWeight(1)

          }
          .width('calc(100% - 32vp)')
          .height(80)
          .margin({
            left: 16,
            right: 16
          })
          .border({
            width: 1,
            color: '#DDDDDD'
          })
          .borderRadius(14)
          .justifyContent(FlexAlign.Center)


          // ==================================================
          // 尊享会员
          // ==================================================

          this.MenuItem(
            '尊享会员',
            'person_crop_circle_fill_1'
          )


          // ==================================================
          // 我的订单
          // ==================================================

          this.MenuItem(
            '我的订单',
            'satellite_map'
          )


          // ==================================================
          // 优惠券
          // ==================================================

          this.MenuItem(
            '优惠券',
            'heart_square_stack_fill'
          )


          // ==================================================
          // 充值中心
          // ==================================================

          this.MenuItem(
            '充值中心',
            'bolt'
          )


          // ==================================================
          // 设置
          // ==================================================

          this.MenuItem(
            '设置',
            'gearshape'
          )


          // ==================================================
          // 帮助中心
          // ==================================================

          this.MenuItem(
            '帮助中心',
            'list_number'
          )


          // ==================================================
          // 退出登录
          // ==================================================

          if (this.userAccount) {

            Button('退出登录')
              .width('calc(100% - 64vp)')
              .height(40)
              .fontSize(14)
              .fontColor('#53AFC0')
              .backgroundColor('#FFFFFF')
              .border({
                width: 1,
                color: '#8CCED8'
              })
              .borderRadius(20)
              .margin({
                left: 32,
                right: 32,
                top: 18,
                bottom: 30
              })
              .onClick(() => {
                this.logout()
              })

          }

        }
        .width('100%')

      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }


  // ==========================================================
  // 下方菜单
  // ==========================================================

  @Builder
  MenuItem(
    title: string,
    iconName: string
  ) {

    Column() {

      Row() {

        // 尊享会员
        if (iconName === 'person_crop_circle_fill_1') {

          SymbolGlyph(
            $r('sys.symbol.person_crop_circle_fill_1')
          )
            .fontSize(21)
            .fontColor(['#444444'])
            .margin({ left: 16 })

        }

        // 我的订单
        else if (iconName === 'satellite_map') {

          SymbolGlyph(
            $r('sys.symbol.satellite_map')
          )
            .fontSize(21)
            .fontColor(['#444444'])
            .margin({ left: 16 })

        }

        // 优惠券
        else if (iconName === 'heart_square_stack_fill') {

          SymbolGlyph(
            $r('sys.symbol.heart_square_stack_fill')
          )
            .fontSize(21)
            .fontColor(['#444444'])
            .margin({ left: 16 })

        }

        // 充值中心
        else if (iconName === 'bolt') {

          SymbolGlyph(
            $r('sys.symbol.bolt')
          )
            .fontSize(21)
            .fontColor(['#444444'])
            .margin({ left: 16 })

        }

        // 设置
        else if (iconName === 'gearshape') {

          SymbolGlyph(
            $r('sys.symbol.gearshape')
          )
            .fontSize(21)
            .fontColor(['#444444'])
            .margin({ left: 16 })

        }

        // 帮助中心
        else if (iconName === 'list_number') {

          SymbolGlyph(
            $r('sys.symbol.list_number')
          )
            .fontSize(21)
            .fontColor(['#444444'])
            .margin({ left: 16 })

        }


        Text(title)
          .fontSize(15)
          .fontColor('#444444')
          .layoutWeight(1)
          .margin({ left: 14 })


        SymbolGlyph(
          $r('sys.symbol.chevron_right')
        )
          .fontSize(16)
          .fontColor(['#999999'])
          .margin({ right: 14 })

      }
      .width('100%')
      .height(55)


      Divider()
        .width('calc(100% - 32vp)')
        .color('#DDDDDD')

    }
    .width('100%')
  }
}