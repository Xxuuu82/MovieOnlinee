export interface UserAccount {
  id:number;
  username?:string;
  password?:string;
  nickname?:string;
  email?:string;
  phone?:string;
  avatarUrl?:string;
  status?:number;
}

export interface UserBalance {
  userId:number;
  balance: number;
}

