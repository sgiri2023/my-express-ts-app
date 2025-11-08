import { Column } from "../components/CustomTable";

export type User = {
  id: number;
  name: string;
  email: string;
  status: "Active" | "Inactive";
};

export const userColumns = (
  handleEdit: (user: User) => void,
  handleDelete: (user: User) => void
): Column<User>[] => [
  {
    header: "Name",
    accessor: "name",
  },
  {
    header: "Email",
    accessor: "email",
  },
  {
    header: "Status",
    render: (row) => (
      <span
        style={{
          color: row.status === "Active" ? "green" : "red",
          fontWeight: "bold",
        }}
      >
        {row.status}
      </span>
    ),
  },
  {
    header: "Actions",
    render: (row) => (
      <>
        <button
          onClick={() => handleEdit(row)}
          style={{ marginRight: "6px", padding: "4px 8px" }}
        >
          Edit
        </button>
        <button onClick={() => handleDelete(row)} style={{ padding: "4px 8px" }}>
          Delete
        </button>
      </>
    ),
  },
];
