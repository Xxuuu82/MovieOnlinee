/**
 * 排片
 */
export interface Schedule {
  id: number;
  cinemaId: number;
  hallId: number;
  movieId: number;

  // 后端返回格式：
  // "2026-01-15T14:00:00"
  showTime: string;

  price: number;
  status: number;
  cinemaName: string;
  hallName: string;
  hallType: string;
  movieName: string;
  moviePoster: string;
  movieDuration: number;
}

export interface ScheduleGroup {
  date: string;
  schedules: Schedule[];
}