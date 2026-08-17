import { Schedule } from "./Schedule";

export interface Order{
  id:number;
  orderNo:string;
  userId:number;
  scheduleId:number;
  hallId:number;
  seatInfo:string;
  amount:number;
  totalPrice:number;
  status:number;
  paymentMethod;
  paymentTime:Date;
  schedule:Schedule;
  hallName:string;
}