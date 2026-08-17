// model/OrderStatus.ts
// 订单状态枚举 - 与数据库保持一致
export enum OrderStatus {
  ALL = 0,        // 全部（前端专用）
  PENDING = 1,    // 待支付
  PAID = 2,       // 已支付
  CANCELLED = 3,  // 已取消
  TICKETED = 4,   // 已出票
  REFUNDED = 5,   // 已退款
  COMPLETED = 6   // 已完成
}

// 订单状态文本映射 - 索引对应状态值
export const OrderStatusText: string[] = [
  '全部',    // 0 - 前端专用
  '待支付',  // 1
  '已支付',  // 2
  '已取消',  // 3
  '已出票',  // 4
  '已退款',  // 5
  '已完成'   // 6
];

// 订单状态颜色映射
export const OrderStatusColor: string[] = [
  '#666666',  // 0 - 全部
  '#faad14',  // 1 - 待支付（橙色）
  '#52c41a',  // 2 - 已支付（绿色）
  '#d9d9d9',  // 3 - 已取消（灰色）
  '#1890ff',  // 4 - 已出票（蓝色）
  '#ff4d4f',  // 5 - 已退款（红色）
  '#52c41a'   // 6 - 已完成（绿色）
];

// 获取订单状态文本
export function getOrderStatusText(status: number): string {
  if (status >= 0 && status < OrderStatusText.length) {
    return OrderStatusText[status];
  }
  return '未知状态';
}

// 获取订单状态颜色
export function getOrderStatusColor(status: number): string {
  if (status >= 0 && status < OrderStatusColor.length) {
    return OrderStatusColor[status];
  }
  return '#666666';
}