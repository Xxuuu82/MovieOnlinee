@Entry
@Component
struct Second {
  @State name: string = ""

  aboutToAppear(): void {
    const params: ESObject = this.getUIContext().getRouter().getParams()
    console.log(params?.name)
    this.name = params?.name;
  }

  build() {
    Row() {
      Text(this.name)
      Button("Back")
        .onClick(() => {
          this.getUIContext().getRouter().back()
        })
    }
    .height('100%')
    .width('100%')
  }
}
