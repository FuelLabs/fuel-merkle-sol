import { utils, BytesLike } from "ethers";

export function hash(data: BytesLike): string {
    return utils.sha256(data);
}