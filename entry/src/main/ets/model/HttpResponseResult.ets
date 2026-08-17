/**
 * 后端统一返回格式
 * 所有接口都返回这个格式
 */
export class HttpResponseResult<T> {
  code: number = 0;      // 200表示成功
  message: string = '';  // 提示信息
  data: T | null = null; // 实际的数据
}