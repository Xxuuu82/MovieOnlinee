/**
 * 排片
 */
export  interface Schedule {
  id:number;
  cinemaId:number;
  hallId:number;
  movieId:number;
  showTime:Date;
  price:number;
  status:number;
  cinemaName:string;
  hallName:string;
  hallType:string;
  movieName:string;
  moviePoster:string;
  movieDuration:number;
}

export interface ScheduleGroup {
  date: string
  schedules: Schedule[]
}