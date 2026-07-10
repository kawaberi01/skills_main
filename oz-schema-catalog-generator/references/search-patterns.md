# Search Patterns

PowerShell で実行する。`rg` を優先する。

## Context の探索

```powershell
rg -n "class .*Context|ConnectionStringName|DbSet<|OnModelCreating" "<db-project-path>"
```

## テーブル・カラム・キー・FK の探索

```powershell
rg -n "ToTable\\(|HasColumnName|HasColumnType|HasKey|HasForeignKey|HasConstraintName|HasIndex|IsUnique" "<db-project-path>\\Models"
```

## Entity プロパティの探索

```powershell
rg -n "public .* { get; set; }|public virtual ICollection|public virtual .* { get; set; }" "<db-project-path>\\Models"
```

## Enum / const の探索

```powershell
rg -n "enum |const |static readonly|public static" "<db-project-path>"
```

## Migration の探索

```powershell
rg -n "CreateTable|DropTable|AddColumn|DropColumn|RenameColumn|RenameTable|AlterColumn|InsertData|UpdateData" "<db-project-path>\\Migrations"
```

## 頻出テーブル確認

```powershell
rg -n "ToTable\\(\"(orders|users|addresses|line_items|order_line_items|products|product_units)" "<db-project-path>\\Models"
```

