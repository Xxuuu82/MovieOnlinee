// model/AuthModels.ts
// 这个文件是独立的新文件，不修改任何原有文件

// 登录请求
export interface LoginRequest {
  username: string;
  password: string;
}

// 注册请求
export interface RegisterRequest {
  username: string;
  password: string;
  nickname: string;
  email: string;
  phone: string;
  avatarUrl: string;
}

// 登录响应数据（扩展自UserAccount，但独立定义）
export interface LoginResponseData {
  id: number;
  username: string;
  nickname: string;
  email: string;
  phone: string;
  avatarUrl: string;
  status: number;
  createTime?: string;
  updateTime?: string;
}

// 注册响应数据
export interface RegisterResponseData {
  userId: string;
}