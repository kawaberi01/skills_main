# LINQパターン集 — idoz0804db (iDrugStore.Callcenter)

iDrugStore.Callcenter の Controller 実装から抽出した、idoz0804db に対するクエリパターン集。
SQL生成の際に JOIN・INNER JOIN・LEFT JOIN の正確なパターンを導出するために使用する。

---

## 1. orders テーブルの取得パターン

### 1-1. ID指定（基本形）
```csharp
serviceFactory.OrderService.GetAll()
    .Where(o => o.Id == orderId)
    .Include(o => o.OrderLineItems)
        .ThenInclude(li => li.ProductUnit.Product)
    .Include(o => o.OrderLineItems)
        .ThenInclude(li => li.ProductUnit.ProductUnitOrders)
    .SingleOrDefault();
```

#### SQL等価パターン
```sql
FROM orders o
INNER JOIN order_line_items oli ON o.id = oli.order_id
INNER JOIN product_units pu ON oli.product_unit_id = pu.id
INNER JOIN products p ON pu.product_id = p.id
LEFT JOIN product_unit_orders puo ON pu.id = puo.product_unit_id
WHERE o.id = @orderId
```

### 1-2. 注文番号(No)指定
```csharp
serviceFactory.OrderService.GetAll()
    .Where(o => o.No == orderParam.No)
    .Include(o => o.OrderLineItems)
        .ThenInclude(li => li.ProductUnit.Product)
    .Include(o => o.OrderLineItems)
        .ThenInclude(li => li.ProductUnit.ProductUnitOrders)
    .SingleOrDefault();
```

> `orders.id` と `orders.no` のどちらでも WHERE 指定ができる。  
> `no` は注文番号（表示番号）、`id` は PK。

---

## 2. 住所（addresses）の取得パターン

### 2-1. 請求先住所 (OrderBillingAddress)

```csharp
serviceFactory.AddressService.GetOrderBillingAddress(order.Id);
// 内部実装:
// GetAll().OfType<OrderBillingAddress>()
//         .SingleOrDefaultAsync(a => a.AddressTypeId == orderId)
```

#### SQL等価パターン
```sql
-- AddressType はテーブルの継承識別子（TPH）
FROM addresses
WHERE address_type = 'OrderBilling'
  AND address_type_id = @orderId
```

### 2-2. 配送先住所 (OrderShippingAddress)

```csharp
serviceFactory.AddressService.GetOrderShippingAddress(order.Id);
// 内部実装:
// GetAll().OfType<OrderShippingAddress>()
//         .SingleOrDefaultAsync(a => a.AddressTypeId == orderId)
```

#### SQL等価パターン
```sql
FROM addresses
WHERE address_type = 'OrderShipping'
  AND address_type_id = @orderId
```

### AddressType 識別子一覧（addresses.address_type の文字列値）
| 識別子文字列 | クラス | 用途 |
|---|---|---|
| `User` | UserAddress | ユーザー住所 |
| `OrderBilling` | OrderBillingAddress | 注文請求先 |
| `OrderShipping` | OrderShippingAddress | 注文配送先 |
| `PeriodicalOrderShipping` | PeriodicalOrderShippingAddress | 定期購入配送先 |

---

## 3. order_line_items の単体取得

```csharp
serviceFactory.OrderLineItemService.GetAll()
    .Where(item => item.Id == order_line_item_id)
    .ToListAsync();
```

#### SQL等価パターン
```sql
FROM order_line_items
WHERE id = @order_line_item_id
```

---

## 4. product_unit_orders のフィルタ

```csharp
serviceFactory.ProductUnitOrderService.GetAll()
    .Where(puo => (int)puo.SupplierId == viewModel.SupplierId && puo.Output)
    .Select(puo => puo.ProductUnitId)
    .ToListAsync();
```

#### SQL等価パターン
```sql
FROM product_unit_orders
WHERE CAST(supplier_id AS INT) = @supplierId
  AND output = 1
```

---

## 5. product_unit_pcas のフィルタ

```csharp
serviceFactory.ProductUnitPcaService.GetAll()
    .Where(pup => pup.PcaCode == viewModel.PcaCode)
    .Select(pup => pup.ProductUnitId)
    .ToListAsync();
```

#### SQL等価パターン
```sql
FROM product_unit_pcas
WHERE pca_code = @pcaCode
```

---

## 6. shipment_requests のフィルタ

```csharp
// ShipmentRequestNo で1件取得
serviceFactory.ShipmentRequestService.GetAll()
    .Where(sr => sr.ShipmentRequestNo == info.shipment_request_no)
    .FirstOrDefault();

// OrderId で複数取得
serviceFactory.ShipmentRequestFailureService.GetAll()
    .Where(s => s.OrderId == orderId)
    .ToList();

// ShipmentReturnFees: OrderId + 降順
serviceFactory.GetService<ShipmentReturnFeeService>().GetAll()
    .Where(srf => srf.OrderId == viewModel.OrderId)
    .OrderByDescending(srf => srf.CreatedAt)
    .ToList();
```

#### SQL等価パターン
```sql
FROM shipment_requests WHERE shipment_request_no = @no
FROM shipment_request_failures WHERE order_id = @orderId
FROM shipment_return_fees WHERE order_id = @orderId ORDER BY created_at DESC
```

---

## 7. user_favorite_categories のフィルタ（カテゴリ結合）

```csharp
serviceFactory.GetService<UserFavoriteCategoryService>()
    .GetAll(true, true)
    .Include(m => m.BigCategory)
    .Include(m => m.MdlCategory)
    .Where(m => m.UserId == userId)
    .OrderByDescending(ul => ul.Id)
    .ToListAsync();
```

#### SQL等価パターン
```sql
FROM user_favorite_categories ufc
LEFT JOIN big_categories bc ON ufc.big_category_id = bc.id
LEFT JOIN mdl_categories mc ON ufc.mdl_category_id = mc.id
WHERE ufc.user_id = @userId
ORDER BY ufc.id DESC
```

> `MdlCategoryId` は nullable → LEFT JOIN。

---

## 8. user_favorites (ほしい物リスト) のフィルタ

```csharp
serviceFactory.UserFavoriteService
    .GetAll(asNoTracking: true)
    .Include(m => m.Product)
    .Where(m => m.UserId == userId)
    .OrderByDescending(ul => ul.Id)
    .ToListAsync();
```

#### SQL等価パターン
```sql
FROM user_favorites uf
INNER JOIN products p ON uf.product_id = p.id
WHERE uf.user_id = @userId
ORDER BY uf.id DESC
```

---

## 9. products.product_categories のフィルタ

```csharp
// MainCategory フラグで絞り込み
.Where(pc => pc.MainCategory)
```

#### SQL等価パターン
```sql
WHERE product_categories.main_category = 1
```

---

## 10. 補足：Include の JOIN 種別の判定方法

| LINQ | SQL訳 |
|---|---|
| `.Include(o => o.OrderLineItems)` | INNER JOIN（通常、外部キー必須の関係） |
| `.Include(m => m.BigCategory)` | INNER JOIN（BigCategoryId は必須） |
| `.Include(m => m.MdlCategory)` | LEFT JOIN（MdlCategoryId は nullable） |
| `.ThenInclude(li => li.ProductUnit.Product)` | INNER JOIN（段階的解決。ProductUnit→Product） |
| `.ThenInclude(li => li.ProductUnit.ProductUnitOrders)` | LEFT JOIN（ProductUnit→ProductUnitOrders は1:多） |

> EF Core では nullable 外部キーは LEFT JOIN、非 nullable は INNER JOIN が生成される。
> SQL生成時はスナップショットの `IsRequired()` / nullable 定義を参照して正確な JOIN 種別を決定する。
