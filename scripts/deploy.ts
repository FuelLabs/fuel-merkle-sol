import { setupFuel } from "../protocol/harness";

async function main() {
  // Setup Fuel.
  const env = await setupFuel({});

  // Emit the primary Fuel address
  console.log("Fuel address:", env.fuel.address); // eslint-disable-line no-console
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error); // eslint-disable-line no-console
    process.exit(1);
  });
