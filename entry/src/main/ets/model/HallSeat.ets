export interface HallSeat{
  hallId:number;
  hallName:string;
  rowCount:number;
  colCount:number;
  seatRows:Array<SeatRow>;
}
export interface SeatRow {
  rowIndex:number;
  rowName:string;
  seats:Array<Seat>;
}
export interface Seat {
  colIndex:number;
  seatCode:string;
  status:number;
}