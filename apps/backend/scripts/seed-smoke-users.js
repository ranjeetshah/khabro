const { PrismaClient } = require('./src/generated/prisma');
const prisma = new PrismaClient();

async function main() {
  const userA = await prisma.user.upsert({
    where: { phone: '+919876543310' },
    update: {},
    create: { phone: '+919876543310', name: 'Citizen A', role: 'CITIZEN' }
  });
  const userB = await prisma.user.upsert({
    where: { phone: '+919876543311' },
    update: { role: 'MODERATOR' },
    create: { phone: '+919876543311', name: 'Moderator B', role: 'MODERATOR' }
  });
  console.log('User A:', userA.id, userA.role);
  console.log('User B:', userB.id, userB.role);
  await prisma.disconnect();
}

main().catch(e => { console.error(e); process.exit(1); });
