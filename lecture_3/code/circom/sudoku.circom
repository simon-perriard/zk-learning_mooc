pragma circom 2.0.6;

template NonEqual(){
    signal input in0;
    signal input in1;
    signal inv;
    // check that (in0-in1) != 0
    inv <-- 1/ (in0 - in1);
    inv*(in0 - in1) === 1;
}

template Distinct(n) {
    signal input in[n];
    component nonEqual[n][n];
    for(var i = 0; i < n; i++){
        for(var j = 0; j < i; j++){
            nonEqual[i][j] = NonEqual();
            nonEqual[i][j].in0 <== in[i];
            nonEqual[i][j].in1 <== in[j];
        }
    }
}

// Enforce that 0 <= in < 16
template Bits4(){
    signal input in;
    signal bits[4];
    var bitsum = 0;
    for (var i = 0; i < 4; i++) {
        bits[i] <-- (in >> i) & 1;
        bits[i] * (bits[i] - 1) === 0;
        bitsum = bitsum + 2 ** i * bits[i];
    }
    bitsum === in;
}

// Enforce that 1 <= in <= 9
template OneToNine() {
    signal input in;
    component lowerBound = Bits4();
    component upperBound = Bits4();
    lowerBound.in <== in - 1;
    upperBound.in <== in + 6;
}

template Sudoku(n) {
    // solution is a 2D array: indices are (row_i, col_i)
    signal input solution[n][n];
    // puzzle is the same, but a zero indicates a blank
    signal input puzzle[n][n];

    component distinctInCol[n];
    component distinctInRow[n];
    component distinctInSubGrid[n];

    component inRange[n][n];

    // Check that puzzle is the same
    for (var row_i = 0; row_i < n; row_i++) {
        for (var col_i = 0; col_i < n; col_i++) {
            // we could make this a component
            puzzle[row_i][col_i] * (puzzle[row_i][col_i] - solution[row_i][col_i]) === 0;
        }
    }

    var total_count = 0;
    var tick_count = 0;

    for (var row_i = 0; row_i < n; row_i++) {
        for (var col_i = 0; col_i < n; col_i++) {
            if (row_i == 0) {
                // Assign a new distinct checker for each column
                distinctInCol[col_i] = Distinct(n);
            }

            if (col_i == 0) {
                // Assign a new distinct checker for each row
                distinctInRow[row_i] = Distinct(n);
            }

            if (row_i % 3 == 0 && col_i % 3 == 0) {
                // Assigne a new disctinct checker for each subgrid
                distinctInSubGrid[row_i + col_i\3] = Distinct(n);
            }

            // Check that elements of the solutions are 1 <= x <= 9
            inRange[row_i][col_i] = OneToNine();
            inRange[row_i][col_i].in <== solution[row_i][col_i];

            // For each column, check that each every elements are distincts
            distinctInCol[col_i].in[row_i] <== solution[row_i][col_i];

            // For each row, check that each every elements are distincts 
            distinctInRow[row_i].in[col_i] <== solution[row_i][col_i];

            // For each subgrid, check that each every elements are distincts
            var grid_subrow = (total_count \ 27) * 3;
            var grid_subcolumn = (total_count % 9 ) \ 3; // ((total_count % 27) % 9 ) \ 3;
            var subgrid = grid_subrow + grid_subcolumn;
            var subgrid_inner_row = ((total_count \ 9) % 3) * 3;
            var subgrid_inner_column = total_count % 3; // (total_count % 9) % 3;
            var subgrid_inner_idx = subgrid_inner_row + subgrid_inner_column;
            
            distinctInSubGrid[subgrid].in[subgrid_inner_idx] <== solution[row_i][col_i];
            total_count += 1;
        }
    }
}

component main {public[puzzle]} = Sudoku(9);

