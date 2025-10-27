String nameForVar(String name) =>
    '__coal_${name.replaceAll(r'-', r'_').replaceAll(r':', r'_')}';
