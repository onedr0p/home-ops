export async function logfmt(message, logLevel = "info") {
    const date = new Date();
    const formatted = date.toISOString();
    let color;
    if (logLevel == "info") { color = chalk.white; }
    if (logLevel == "error") { color = chalk.red; }
    console.log(color(`timestamp="${formatted}" level="${logLevel}" message="${message}"`))
}
