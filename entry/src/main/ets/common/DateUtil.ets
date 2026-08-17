//转成年月日时分秒
export function formatDateTime(isoStr: string): string {
  const date = new Date(isoStr);
  const y = date.getFullYear();
  const m = date.getMonth() + 1;
  const d = date.getDate();
  const h = String(date.getHours()).padStart(2, '0');
  const min = String(date.getMinutes()).padStart(2, '0');
  return `${y}年${m}月${d}日 ${h}:${min}`;
}

export function formatDate(isoStr: string): string {
  const date = new Date(isoStr);
  const y = date.getFullYear();
  const m = date.getMonth() + 1;
  const d = date.getDate();
  return `${y}年${m}月${d}日`;
}
export function formatMonthDate(isoStr: string): string {
  const date = new Date(isoStr);
  const m = date.getMonth() + 1;
  const d = date.getDate();
  return `${m}月${d}日`;
}
export function formatStartTime(isoStr: string): string {
  const date = new Date(isoStr);
  const h = String(date.getHours()).padStart(2, '0');
  const min = String(date.getMinutes()).padStart(2, '0');
  return `${h}:${min}`;
}
export function formatEndTime(isoStr: string,duration:number): string {
  const date = new Date(isoStr);
  const newDate = new Date(date.getTime()+duration*60*1000);
  const h = String(newDate.getHours()).padStart(2, '0');
  const min = String(newDate.getMinutes()).padStart(2, '0');
  return `${h}:${min}`;
}