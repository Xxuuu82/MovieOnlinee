import { MovieType } from './MovieType';

/**
 * 电影数据模型
 * 对应后端返回的电影信息
 */
export class Movie {
  id: number = 0;
  movieName: string = '';
  director: string = '';
  actors: string = '';
  type: string = '';
  duration: number = 0;
  releaseDate: string = '';
  description: string = '';
  posterUrl: string = '';
  trailerUrl: string = '';
  status: number = 0;
  movieRating: number = 0;
  createTime: string = '';
  updateTime: string = '';
  movieTypes?: MovieType[]; // 可选：电影类型列表
}