import { MovieType } from "./MovieType";

export interface Movie {
  id:number;
  movieName:string;
  director:string;
  actors:string;
  type:string;
  duration:number;
  releaseDate:Date;
  description:string;
  posterUrl:string;
  trailerUrl:string;
  status:number;
  movieTypes:Array<MovieType>;
  movieRating:number;
}