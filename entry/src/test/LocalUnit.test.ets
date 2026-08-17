import { describe, it, expect } from '@ohos/hypium';
import { MovieType } from '../main/ets/model/MovieType';
import { UserAccount } from '../main/ets/model/UserAccount';
import {
  formatCommentDate,
  formatMovieDate,
  getCommentUserName,
  getMovieTypeText,
  isCurrentUserStateRequest,
  ratingToStars,
  starsToRating
} from '../main/ets/common/MovieDetailUtil';

export default function localUnitTest() {
  describe('localUnitTest', () => {
    it('assertContain', 0, () => {
      let a = 'abc';
      let b = 'b';
      expect(a).assertContain(b);
      expect(a).assertEqual(a);
    });

    it('formatMovieType', 0, () => {
      const action = new MovieType();
      action.typeName = '动作';
      const fantasy = new MovieType();
      fantasy.typeName = '奇幻';

      expect(getMovieTypeText([action, fantasy], '1,3')).assertEqual('动作 / 奇幻');
      expect(getMovieTypeText(undefined, '剧情')).assertEqual('剧情');
      expect(getMovieTypeText(undefined, '')).assertEqual('类型待定');
    });

    it('formatMovieDetailDate', 0, () => {
      expect(formatMovieDate('2026-07-19T00:00:00')).assertEqual('2026年7月19日');
      expect(formatCommentDate('2026-08-17T05:39:00')).assertEqual('2026年8月17日 05:39');
      expect(formatMovieDate('')).assertEqual('待定');
      expect(formatCommentDate('')).assertEqual('');
    });

    it('convertMovieRating', 0, () => {
      expect(ratingToStars(9)).assertEqual(4.5);
      expect(starsToRating(4.5)).assertEqual(9);
    });

    it('ignoreExpiredUserStateRequest', 0, () => {
      expect(isCurrentUserStateRequest(2, 2, 5, 5)).assertTrue();
      expect(isCurrentUserStateRequest(1, 2, 5, 5)).assertFalse();
      expect(isCurrentUserStateRequest(2, 2, 4, 5)).assertFalse();
    });

    it('getCommentDisplayName', 0, () => {
      const account: UserAccount = {
        id: 1,
        username: 'test_user',
        nickname: '测试用户'
      };

      expect(getCommentUserName(account)).assertEqual('测试用户');
      expect(getCommentUserName({ id: 2, username: 'movie_user' })).assertEqual('movie_user');
      expect(getCommentUserName(undefined)).assertEqual('电影用户');
    });
  });
}
