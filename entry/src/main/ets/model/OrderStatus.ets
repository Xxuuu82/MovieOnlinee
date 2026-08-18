export enum OrderStatus {
  ALL = 0,        // 全部（前端专用，不传给后端）
  PENDING = 1,    // 待支付
  PAID = 2,       // 已支付
  CANCELLED = 3,  // 已取消
  REFUNDED = 5,   // 已退款
  COMPLETED = 6   // 已完成
}

/**
 * 订单状态文本映射
 * 索引对应状态值
 */
export const OrderStatusText: Record<number, string> = {
  0: '全部',      // 前端专用
  1: '待支付',
  2: '已支付',
  3: '已取消',
  5: '已退款',
  6: '已完成'
};

/**
 * 订单状态颜色映射
 * 索引对应状态值
 */
export const OrderStatusColor: Record<number, string> = {
  0: '#666666',   // 全部
  1: '#FAAD14',   // 待支付 - 橙色
  2: '#1890FF',   // 已支付 - 蓝色
  3: '#999999',   // 已取消 - 灰色
  5: '#FF4D4F',   // 已退款 - 红色
  6: '#52C41A'    // 已完成 - 绿色
};

/**
 * 获取订单状态文本
 */
export function getOrderStatusText(status: number): string {
  return OrderStatusText[status] || '未知状态';
}

/**
 * 获取订单状态颜色
 */
export function getOrderStatusColor(status: number): string {
  return OrderStatusColor[status] || '#666666';
}