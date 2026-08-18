import { UserAccount } from "./UserAccount";

export interface MovieComment {
  id:number;
  userId:number;
  movieId:number;
  rating:number;
  content:string;
  createTime:string;
  updateTime:string;
  userAccount?:UserAccount;
}
