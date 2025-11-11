import { MigrationInterface, QueryRunner } from "typeorm";

export class SeedSampleUsers1731268000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Fetch ADMIN and VIEWER role IDs
    const adminRole = await queryRunner.query(
      `SELECT id FROM roles WHERE role_key = 'ADMIN' LIMIT 1`
    );
    const viewerRole = await queryRunner.query(
      `SELECT id FROM roles WHERE role_key = 'VIEWER' LIMIT 1`
    );

    if (!adminRole.length || !viewerRole.length) {
      console.warn('⚠️  Required roles (ADMIN, VIEWER) not found — skipping user insert.');
      return;
    }

    // Insert sample users
    await queryRunner.query(`
      INSERT INTO "Users" (firstname, lastname, email, "roleId", is_active, created_at, updated_at)
      VALUES 
        ('John', 'Admin', 'admin@example.com', '${adminRole[0].id}', true, NOW(), NOW()),
        ('Jane', 'Viewer', 'viewer@example.com', '${viewerRole[0].id}', true, NOW(), NOW())
      ON CONFLICT (email) DO NOTHING;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DELETE FROM "Users" 
      WHERE email IN ('admin@example.com', 'viewer@example.com');
    `);
  }
}
