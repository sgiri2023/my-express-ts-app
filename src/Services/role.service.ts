import { AppDataSource } from "../data-source";
import { Role } from "../entities/Role";

export class RoleService {
    private roleRepo = AppDataSource.getRepository(Role);

    async getAllRoles(): Promise<Role[]> {
        return this.roleRepo.find();
    }

    async getRoleById(role_id: number): Promise<Role | null> {
        return this.roleRepo.findOne({ where: { role_id } });
    }

    async createRole(data: Partial<Role>): Promise<Role> {
        const role = this.roleRepo.create(data);
        return this.roleRepo.save(role);
    }

    async updateRole(role_id: number, data: Partial<Role>): Promise<Role | null> {
        await this.roleRepo.update(role_id, data);
        return this.getRoleById(role_id);
    }

    async deleteRole(role_id: number): Promise<void> {
        await this.roleRepo.delete(role_id);
    }
}
