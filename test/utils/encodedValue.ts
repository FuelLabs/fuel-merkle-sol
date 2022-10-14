interface EncodedValueInput {
    value: string;
    encoding: BufferEncoding;
}

class EncodedValue {
    value: string;

    encoding: BufferEncoding;

    constructor(item: EncodedValueInput) {
        this.value = item.value;
        this.encoding = item.encoding;
    }

    toString(): string {
        if (this.encoding === 'hex') {
            return `0x${this.value}`;
        }

        return this.value;
    }

    toBuffer(): Uint8Array {
        return Buffer.from(this.value, this.encoding);
    }
}

export {EncodedValueInput, EncodedValue};