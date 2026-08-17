import { MovieType } from "./MovieType";

export interface Movie{
  movieId: string;
  id?:number,
  movieName?:string,
  directo?:string,
  actors?:string,
  duration?:number,
  releaseDate?:Date,
  description?:string,
  posterUrl?:string,
  trailerUrl?:string,
  status?:number,
  movieRating?:number,
  movieTypes?:MovieType[]






}