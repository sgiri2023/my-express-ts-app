import React from "react";
import CustomTable from "./components/CustomTable";
import { userColumns, User } from "./tables/userColumns";

export default function App() {
  const handleEdit = (user: User) => alert(`Edit ${user.name}`);
  const handleDelete = (user: User) => alert(`Delete ${user.name}`);

  const data: User[] = [
    { id: 1, name: "Alice", email: "alice@example.com", status: "Active" },
    { id: 2, name: "Bob", email: "bob@example.com", status: "Inactive" },
  ];

  const columns = userColumns(handleEdit, handleDelete);

  return <CustomTable<User> columns={columns} data={data} />;
}
