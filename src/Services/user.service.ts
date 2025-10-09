import { AppDataSource } from "../data-source";
import { User } from "../entities/User";
import { UserAuditLog } from "../entities/UserAuditLog";
import { ActionType } from "../enums/ActionType";

export class UserService {
    private userRepo = AppDataSource.getRepository(User);
    private auditRepo = AppDataSource.getRepository(UserAuditLog);

    async getAllUsers(): Promise<User[]> {
        return this.userRepo.find();
    }

    async getUserById(user_id: number): Promise<User | null> {
        return this.userRepo.findOne({ where: { user_id } });
    }

    async loginUser(email: string): Promise<Partial<User> | null> {
        return this.userRepo.findOne({
            where: { email },
            select: ["user_id", "email", "is_active", "is_global_admin", "created_at", "updated_at"], // pick only safe fields
        });
        }

    async createUser(data: Partial<User>, actorUserId: number): Promise<User> {
        const user = this.userRepo.create(data);
        const savedUser = await this.userRepo.save(user);

        // Create audit log
        await this.auditRepo.save({
            actor_user: { user_id: actorUserId },
            target_user: savedUser,
            action_type: ActionType.CREATE_USER,
            new_value: JSON.stringify(savedUser)
        });

        return savedUser;
    }

    async updateUser(user_id: number, data: Partial<User>, actorUserId: number): Promise<User | null> {
        const user = await this.getUserById(user_id);
        if (!user) return null;

        const oldValue = JSON.stringify(user);
        await this.userRepo.update(user_id, data);
        const updatedUser = await this.getUserById(user_id);

        // Create audit log
        await this.auditRepo.save({
            actor_user: { user_id: actorUserId },
            target_user: updatedUser!,
            action_type: ActionType.UPDATE_USER,
            old_value: oldValue,
            new_value: JSON.stringify(updatedUser)
        });

        return updatedUser;
    }

    async softDeleteUser(
        id: number,
        actorUserId: number,
        isActive: boolean = false
        ): Promise<User | null> {
        const user = await this.userRepo.findOne({ where: { user_id: id } });
        if (!user) return null;

        const actorUser = await this.userRepo.findOne({ where: { user_id: actorUserId } });
        if (!actorUser) throw new Error("Actor user not found");

        user.is_active = isActive;
        user.updated_at = new Date(); // ✅ update timestamp manually

        const savedUser = await this.userRepo.save(user);

        await this.auditRepo.save({
            actor_user: actorUser,
            target_user: savedUser,
            action_type: isActive ? ActionType.ACTIVATE_USER : ActionType.DEACTIVATE_USER,
            old_value: JSON.stringify({ is_active: !isActive }),
            new_value: JSON.stringify({ is_active: isActive }),
        });

        return savedUser;
        }


    async deleteUser(user_id: number, actorUserId: number): Promise<void> {
        const user = await this.getUserById(user_id);
        if (!user) return;

        await this.userRepo.delete(user_id);

        // Create audit log
        await this.auditRepo.save({
            actor_user: { user_id: actorUserId },
            target_user: user,
            action_type: ActionType.DELETE_USER,
            old_value: JSON.stringify(user)
        });
    }
}
