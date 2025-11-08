import React from "react";

export type Column<T> = {
  header: string;
  accessor?: keyof T;
  render?: (row: T) => React.ReactNode;
};

export interface CustomTableProps<T> {
  columns: Column<T>[];
  data: T[];
  emptyMessage?: string;
}

function CustomTable<T extends { id?: string | number }>({
  columns,
  data,
  emptyMessage = "No data available",
}: CustomTableProps<T>) {
  return (
    <div style={{ overflowX: "auto" }}>
      <table style={{ width: "100%", borderCollapse: "collapse" }}>
        <thead>
          <tr style={{ backgroundColor: "#f5f5f5" }}>
            {columns.map((col, index) => (
              <th
                key={index}
                style={{
                  border: "1px solid #ddd",
                  padding: "8px",
                  textAlign: "left",
                }}
              >
                {col.header}
              </th>
            ))}
          </tr>
        </thead>

        <tbody>
          {data.length > 0 ? (
            data.map((row, rowIndex) => (
              <tr key={row.id ?? rowIndex}>
                {columns.map((col, colIndex) => (
                  <td
                    key={colIndex}
                    style={{
                      border: "1px solid #ddd",
                      padding: "8px",
                    }}
                  >
                    {col.render
                      ? col.render(row)
                      : col.accessor
                      ? (row[col.accessor] as React.ReactNode)
                      : null}
                  </td>
                ))}
              </tr>
            ))
          ) : (
            <tr>
              <td
                colSpan={columns.length}
                style={{
                  textAlign: "center",
                  padding: "10px",
                }}
              >
                {emptyMessage}
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

export default CustomTable;
