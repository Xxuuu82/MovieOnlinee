import { formatDate, formatDateTime } from './DateUtil';
import { MovieType } from '../model/MovieType';
import { UserAccount } from '../model/UserAccount';

// 优先使用后端返回的类型名称
export function getMovieTypeText(movieTypes: MovieType[] | undefined, fallback: string): string {
  if (movieTypes && movieTypes.length > 0) {
    const typeNames: string[] = [];
    movieTypes.forEach((item: MovieType) => {
      if (item.typeName.trim().length > 0) {
        typeNames.push(item.typeName);
      }
    });
    if (typeNames.length > 0) {
      return typeNames.join(' / ');
    }
  }

  const trimmedFallback: string = fallback.trim();
  if (trimmedFallback.length > 0) {
    // Movie.type可能是逗号分隔的类型ID，不在页面显示原始ID
    if (/^\d+(?:\s*,\s*\d+)*$/.test(trimmedFallback)) {
      return '类型待定';
    }
    return trimmedFallback;
  }
  return '类型待定';
}

// 电影上映日期只显示年月日
export function formatMovieDate(value: string): string {
  if (value.length === 0) {
    return '待定';
  }
  return formatDate(value);
}

// 评论时间保留到分钟
export function formatCommentDate(value: string): string {
  if (value.length === 0) {
    return '';
  }
  return formatDateTime(value);
}

// 后端使用10分制，Rating组件使用5星制
export function ratingToStars(rating: number): number {
  return rating / 2;
}

// 页面5星制转换为后端10分制
export function starsToRating(stars: number): number {
  return Math.round(stars * 2);
}

// 只有当前用户的最新请求可以更新页面状态
export function isCurrentUserStateRequest(
  requestUserId: number,
  currentUserId: number,
  requestId: number,
  currentRequestId: number
): boolean {
  return requestUserId === currentUserId && requestId === currentRequestId;
}

// 评论用户优先显示昵称
export function getCommentUserName(userAccount: UserAccount | undefined): string {
  if (userAccount?.nickname && userAccount.nickname.trim().length > 0) {
    return userAccount.nickname;
  }
  if (userAccount?.username && userAccount.username.trim().length > 0) {
    return userAccount.username;
  }
  return '电影用户';
}
