import { Movie } from "./Movie";

export interface MovieFavorite{
  id?:number;
  userId?:number;
  movieId?:number;
  favoriteMovie?:Movie;
}