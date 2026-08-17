import { http } from "@kit.NetworkKit";

export class  HttpUtil{
  BASE_URL:string="http://10.98.15.30:8081/movieplatform";
  private request<T>(url:string,method:http.RequestMethod,extraData?:Object):Promise<T>{
		return new Promise((resolve,reject)=>{
      let httpRequest = http.createHttp();
      httpRequest.request(
        this.BASE_URL+url,
        {
          method: method,
          header: {
            'Content-Type': 'application/json'
          },
          extraData:extraData?JSON.stringify(extraData):undefined
        }, (err: BusinessError, data: http.HttpResponse) => {
        httpRequest.destroy();
        if (!err) {
         resolve(JSON.parse(`${data.result}`));
        } else {
         reject(err);
        }
      }
      );
    });
	}
  get<T>(url:string):Promise<T>{
		return this.request(url,http.RequestMethod.GET);
	}

  post<T>(url:string,parmas:ESObject):Promise<T>{
    return this.request(url,http.RequestMethod.POST,parmas);
  }
}
export default new HttpUtil();