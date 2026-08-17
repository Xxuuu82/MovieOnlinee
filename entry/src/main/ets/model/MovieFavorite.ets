import { Movie } from "../model/Movie";

export interface MovieFavorite{
  id?:number;
  userId?:number;
  movieId?:number;
  favoriteMovie?:Movie;
}