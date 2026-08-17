import { http } from "@kit.NetworkKit";

export class  HttpUtil{
  BASE_URL:string="http://10.98.10.164:8081/movieplatform";
  static BASE_URL: string | undefined;

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
  get<T>(url: string, params?: Record<string, string | number>): Promise<T> {
    // 如果有参数，拼接到 URL 后面
    let fullUrl = url;
    if (params) {
      const keys = Object.keys(params);
      const queryParts: string[] = [];
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const value = params[key];
        if (value !== undefined && value !== null && value !== '') {
          queryParts.push(`${key}=${encodeURIComponent(String(value))}`);
        }
      }
      if (queryParts.length > 0) {
        fullUrl = url + '?' + queryParts.join('&');
      }
    }
    return this.request<T>(fullUrl, http.RequestMethod.GET);
  }

  post<T>(url:string,parmas:Object):Promise<T>{
    return this.request(url,http.RequestMethod.POST,parmas);
  }
}
export default new HttpUtil();