final _regex = RegExp(r'[-:]');

String nameForVar(String name) => name.replaceAll(_regex, '_');
