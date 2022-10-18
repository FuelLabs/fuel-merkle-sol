import { EncodedValueInput } from './encodedValue';

export default interface ProofTest {
	name: string;
	root: EncodedValueInput;
	proof_set: EncodedValueInput[];
	proof_index: number;
	num_leaves: number;
	expected_verification: boolean;
}
